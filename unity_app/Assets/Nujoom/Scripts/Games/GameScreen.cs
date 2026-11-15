using System;
using UnityEngine;
using UnityEngine.UI;

namespace Nujoom
{
    /// <summary>
    /// Hosts any game template. It owns what all games share - the mascot's
    /// reactions, sound effects, saving stars and the result panel - so a
    /// template only has to report "right", "wrong" and "finished".
    ///
    /// To add a new template: write a view class like ChoiceView, then add
    /// one case in StartTemplate().
    /// </summary>
    public class GameScreen
    {
        private readonly Topic topic;
        private readonly Activity activity;
        private RectTransform root;
        private RectTransform area;
        private Mascot mascot;

        public static void Open(Topic topic, Activity activity)
        {
            new GameScreen(topic, activity).Build();
        }

        private GameScreen(Topic topic, Activity activity)
        {
            this.topic = topic;
            this.activity = activity;
        }

        private void Build()
        {
            root = App.I.NewScreen("Game " + activity.id);

            Ui.RoundButton("Close", root, "X", Leave).At(0.055f, 0.9f, 84f, 84f);

            mascot = Mascot.Create(root, 210f);
            ((RectTransform)mascot.transform).At(0.095f, 0.26f, 210f, 210f);

            area = Ui.Node("Play Area", root).Frac(0.2f, 0.04f, 0.985f, 0.97f);
            StartTemplate();
        }

        private void StartTemplate()
        {
            Clear(area);
            switch (activity.type)
            {
                case "choice": new ChoiceView(this, area, topic, activity); break;
                case "memory": new MemoryView(this, area, topic); break;
                case "match": new MatchView(this, area, topic); break;
                default: Debug.LogError("Nujoom: no template for game type '" + activity.type + "'"); break;
            }
        }

        private void Leave()
        {
            App.I.Sfx.Play(Sfx.Tap);
            TopicScreen.Show(topic);
        }

        // ---- Called by the templates ----

        public void Right()
        {
            App.I.Sfx.Play(Sfx.Correct);
            mascot.Play(MascotMood.Cheer);
        }

        public void Wrong()
        {
            App.I.Sfx.Play(Sfx.Wrong);
            mascot.Play(MascotMood.Sad);
        }

        /// <summary>The game is asking (or repeating) its question.</summary>
        public void Prompt()
        {
            mascot.Play(MascotMood.Talk);
        }

        public void Finish(int stars)
        {
            Store.SaveBest(activity.id, stars);
            App.I.Sfx.Play(Sfx.Win);
            mascot.Play(MascotMood.Cheer);
            ResultPanel.Show(root, stars, () => { App.I.Sfx.Play(Sfx.Tap); Open(topic, activity); }, Leave);
        }

        // ---- Shared pieces the templates use ----

        /// <summary>The instruction strip at the top of a game. Returns its text.</summary>
        public Text MakePrompt(RectTransform parent, string content)
        {
            Card card = Ui.MakeCard("Prompt", parent, Theme.Card);
            card.Root.Frac(0.14f, 0.86f, 0.86f, 0.985f);
            card.FaceImage.raycastTarget = false;
            Text text = Ui.Label("Text", card.Face, content, 40, Theme.Ink);
            text.rectTransform.Fill(18, 6, 18, 6);
            return text;
        }

        /// <summary>A small "2 / 6" progress label in the corner.</summary>
        public Text MakeCounter(RectTransform parent)
        {
            Text text = Ui.Label("Counter", parent, "", 30, Theme.InkSoft);
            text.rectTransform.Frac(0.88f, 0.87f, 1f, 0.975f);
            return text;
        }

        public static void Clear(Transform parent)
        {
            for (int i = parent.childCount - 1; i >= 0; i--)
            {
                UnityEngine.Object.Destroy(parent.GetChild(i).gameObject);
            }
        }
    }

    /// <summary>The celebration at the end of an activity.</summary>
    public static class ResultPanel
    {
        public static void Show(RectTransform screen, int stars, Action onReplay, Action onDone)
        {
            // A full-screen dim layer that also blocks taps on the game below.
            Image dim = Ui.Img("Result", screen, null, Theme.WithAlpha(Theme.Ink, 0.45f), true);
            dim.rectTransform.Fill();

            Card card = Ui.MakeCard("Panel", dim.transform, Theme.Card);
            card.Root.At(0.5f, 0.5f, 640f, 420f);

            string title = stars >= 3 ? Loc.Get("resultGreat") : stars == 2 ? Loc.Get("resultGood") : Loc.Get("resultTry");
            Ui.Label("Title", card.Face, title, 60, Theme.Ink).rectTransform.Frac(0.06f, 0.7f, 0.94f, 0.95f);

            for (int i = 0; i < 3; i++)
            {
                bool earned = i < stars;
                Image star = Ui.Img("Star " + (i + 1), card.Face, Shapes.Star, earned ? Theme.Star : Theme.StarEmpty);
                star.rectTransform.At(0.25f + 0.25f * i, 0.52f, 120f, 120f);
                if (!earned) continue;
                float delay = 0.5f + 0.38f * i;
                Tween.PopIn(star.rectTransform, delay, 0.6f);
                Tween.Delay(dim.gameObject, delay, () => App.I.Sfx.Play(Sfx.Star));
            }

            Ui.TextButton("Replay", card.Face, Loc.Get("playAgain"), Theme.Primary, onReplay).Root.Frac(0.06f, 0.08f, 0.52f, 0.3f);
            Ui.TextButton("Done", card.Face, Loc.Get("done"), Theme.Success, onDone).Root.Frac(0.56f, 0.08f, 0.94f, 0.3f);

            Tween.PopIn(card.Root);
            Confetti.Burst(dim.transform);
        }
    }
}
