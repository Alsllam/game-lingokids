using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace Nujoom
{
    // The menu screens. Each Show() method wipes the previous screen and
    // builds a new one from code.

    /// <summary>The first screen: the mascot says hello and the child picks a world.</summary>
    public static class HomeScreen
    {
        public static void Show()
        {
            App app = App.I;
            RectTransform root = app.NewScreen("Home");

            Ui.Label("Title", root, Loc.Get("appTitle"), 70, Theme.Ink, Ui.StartAlign)
                .rectTransform.FracDir(0.03f, 0.85f, 0.4f, 0.985f);

            Card parents = Ui.TextButton("Parents", root, Loc.Get("parents"), Theme.InkSoft, () =>
            {
                app.Sfx.Play(Sfx.Tap);
                ParentsScreen.Show(false, null);
            }, 28);
            parents.Root.FracDir(0.85f, 0.885f, 0.98f, 0.975f);

            if (app.Catalog == null)
            {
                Ui.Label("Error", root, Loc.Get("loadError"), 44, Theme.Danger).rectTransform.FracDir(0.1f, 0.4f, 0.9f, 0.6f);
                return;
            }

            // Total stars.
            Card chip = Ui.MakeCard("Stars", root, Theme.Card);
            chip.Root.FracDir(0.64f, 0.885f, 0.83f, 0.975f);
            Image chipStar = Ui.Img("Star", chip.Face, Shapes.Star, Theme.Star);
            chipStar.rectTransform.FracDir(0.06f, 0.12f, 0.34f, 0.88f);
            chipStar.preserveAspect = true;
            Ui.Label("Count", chip.Face, Store.TotalStars(app.Catalog).ToString(), 40, Theme.Ink)
                .rectTransform.FracDir(0.36f, 0.08f, 0.94f, 0.92f);

            // The mascot greets, and cheers when tapped.
            Card bubble = Ui.MakeCard("Speech Bubble", root, Theme.Card);
            bubble.Root.FracDir(0.02f, 0.66f, 0.27f, 0.8f);
            Ui.Label("Text", bubble.Face, Loc.Get("greeting"), 30, Theme.Ink).rectTransform.Fill(12, 6, 12, 6);
            Tween.PopIn(bubble.Root, 0.5f);

            Mascot mascot = Mascot.Create(root, 300f);
            var mascotRect = (RectTransform)mascot.transform;
            mascotRect.AtDir(0.145f, 0.36f, 300f, 300f);
            Image touchArea = Ui.Img("Touch Area", mascotRect, null, Color.clear, true);
            touchArea.rectTransform.Fill();
            Ui.OnTap(mascotRect, () =>
            {
                mascot.Play(MascotMood.Cheer);
                app.Sfx.Play(Sfx.Star);
            });
            Tween.Delay(root.gameObject, 0.4f, () => mascot.Play(MascotMood.Wave));

            // One card per world, side by side.
            RectTransform row = Ui.Node("Topics", root).FracDir(0.29f, 0.11f, 0.99f, 0.82f);
            List<Topic> topics = app.Catalog.topics;
            for (int i = 0; i < topics.Count; i++)
            {
                Topic topic = topics[i];
                RectTransform slot = Ui.Node("Slot " + topic.id, row).FracDir((float)i / topics.Count, 0f, (float)(i + 1) / topics.Count, 1f);
                Card card = Ui.MakeCard("Topic", slot, Theme.Hex(topic.color));
                card.Root.Fill(9, 14, 9, 8);

                RectTransform icon = Ui.Node("Icon", card.Face).FracDir(0.06f, 0.36f, 0.94f, 0.97f);
                Visuals.Build(icon, topic.icon, 4f);
                Ui.Label("Title", card.Face, topic.title.Of(Loc.Language), 40, Color.white)
                    .rectTransform.FracDir(0.05f, 0.19f, 0.95f, 0.36f);

                Image pill = Ui.Img("Stars", card.Face, Shapes.Rounded, Theme.WithAlpha(Color.white, 0.92f));
                pill.rectTransform.FracDir(0.14f, 0.05f, 0.86f, 0.17f);
                Image pillStar = Ui.Img("Star", pill.transform, Shapes.Star, Theme.Star);
                pillStar.rectTransform.FracDir(0.06f, 0.1f, 0.3f, 0.9f);
                pillStar.preserveAspect = true;
                Ui.Label("Count", pill.transform, Store.StarsIn(topic) + " / " + topic.activities.Count * 3, 26, Theme.Ink)
                    .rectTransform.FracDir(0.3f, 0.05f, 0.96f, 0.95f);

                Tween.PopIn(card.Root, 0.08f * i);
                Ui.OnTap(card.Root, () =>
                {
                    app.Sfx.Play(Sfx.Tap);
                    TopicScreen.Show(topic);
                });
            }
        }
    }

    /// <summary>Lists the games of one world.</summary>
    public static class TopicScreen
    {
        public static void Show(Topic topic)
        {
            App app = App.I;
            RectTransform root = app.NewScreen("Topic " + topic.id);
            Color accent = Theme.Hex(topic.color);

            Ui.RoundButton("Back", root, Ui.RightToLeft ? ">" : "<", () =>
            {
                app.Sfx.Play(Sfx.Tap);
                HomeScreen.Show();
            }).AtDir(0.055f, 0.9f, 84f, 84f);

            Ui.Label("Title", root, topic.title.Of(Loc.Language), 64, Theme.Ink).rectTransform.FracDir(0.2f, 0.82f, 0.8f, 0.98f);

            RectTransform row = Ui.Node("Activities", root).FracDir(0.08f, 0.12f, 0.92f, 0.78f);
            int count = topic.activities.Count;
            for (int i = 0; i < count; i++)
            {
                Activity activity = topic.activities[i];
                RectTransform slot = Ui.Node("Slot " + activity.id, row).FracDir((float)i / count, 0f, (float)(i + 1) / count, 1f);
                RectTransform square = Ui.SquareIn("Activity", slot, 14f);
                Card card = Ui.MakeCard("Card", square, Theme.Card, accent);
                card.Root.Fill();

                RectTransform icon = Ui.Node("Icon", card.Face).FracDir(0.2f, 0.42f, 0.8f, 0.96f);
                Visuals.Build(icon, IconFor(activity.type, topic.color));
                Ui.Label("Name", card.Face, Loc.Get(NameKey(activity.type)), 40, Theme.Ink)
                    .rectTransform.FracDir(0.06f, 0.24f, 0.94f, 0.42f);
                Ui.StarRow("Stars", card.Face, Store.StarsFor(activity.id)).FracDir(0.24f, 0.06f, 0.76f, 0.23f);

                Tween.PopIn(card.Root, 0.08f * i);
                Ui.OnTap(card.Root, () =>
                {
                    app.Sfx.Play(Sfx.Tap);
                    GameScreen.Open(topic, activity);
                });
            }
        }

        private static string NameKey(string gameType)
        {
            switch (gameType)
            {
                case "memory": return "gameMemory";
                case "match": return "gameMatch";
                default: return "gameChoice";
            }
        }

        // A simple symbol for each template, drawn with the same Visuals code.
        private static ItemVisual IconFor(string gameType, string color)
        {
            switch (gameType)
            {
                case "memory":
                    return new ItemVisual { kind = "dots", value = new LocalizedText { ar = "4", en = "4" }, color = color };
                case "match":
                    return new ItemVisual { kind = "shape", value = new LocalizedText { ar = "heart", en = "heart" }, color = color };
                default:
                    return new ItemVisual { kind = "glyph", value = new LocalizedText { ar = "؟", en = "?" }, color = color };
            }
        }
    }

    /// <summary>
    /// Settings for grown-ups, behind a multiplication question that a young
    /// child will not answer by accident.
    /// </summary>
    public static class ParentsScreen
    {
        public static void Show(bool unlocked, string message)
        {
            App app = App.I;
            RectTransform root = app.NewScreen("Parents");

            Ui.RoundButton("Back", root, Ui.RightToLeft ? ">" : "<", () =>
            {
                app.Sfx.Play(Sfx.Tap);
                HomeScreen.Show();
            }).AtDir(0.055f, 0.9f, 84f, 84f);
            Ui.Label("Title", root, Loc.Get("parents"), 60, Theme.Ink).rectTransform.FracDir(0.2f, 0.82f, 0.8f, 0.98f);

            Card panel = Ui.MakeCard("Panel", root, Theme.Card);
            panel.Root.AtDir(0.5f, 0.42f, 760f, 440f);
            panel.FaceImage.raycastTarget = false;

            if (unlocked) BuildSettings(panel.Face, message);
            else BuildGate(panel.Face, message);
        }

        private static void BuildGate(RectTransform panel, string message)
        {
            int a = Random.Range(3, 9), b = Random.Range(3, 9);
            int correct = a * b;
            var answers = new List<int> { correct };
            while (answers.Count < 4)
            {
                int candidate = correct + Random.Range(-10, 11);
                if (candidate > 0 && !answers.Contains(candidate)) answers.Add(candidate);
            }
            answers = Shuffle.Of(answers, new System.Random());

            Ui.Label("Title", panel, Loc.Get("gateTitle"), 44, Theme.Ink).rectTransform.FracDir(0.05f, 0.76f, 0.95f, 0.95f);
            Ui.Label("Question", panel, Loc.Format("gateQuestion", a, b), 40, Theme.InkSoft).rectTransform.FracDir(0.05f, 0.56f, 0.95f, 0.75f);
            for (int i = 0; i < answers.Count; i++)
            {
                int answer = answers[i];
                Ui.TextButton("Answer " + answer, panel, answer.ToString(), Theme.Primary, () =>
                {
                    App.I.Sfx.Play(Sfx.Tap);
                    if (answer == correct) Show(true, null);
                    else Show(false, Loc.Get("gateWrong"));
                }, 40).Root.FracDir(0.05f + 0.23f * i, 0.26f, 0.26f + 0.23f * i, 0.5f);
            }
            if (!string.IsNullOrEmpty(message))
            {
                Ui.Label("Message", panel, message, 30, Theme.Danger).rectTransform.FracDir(0.05f, 0.05f, 0.95f, 0.2f);
            }
        }

        private static bool resetArmed;

        private static void BuildSettings(RectTransform panel, string message)
        {
            // Language
            Ui.Label("Language", panel, Loc.Get("language"), 34, Theme.Ink).rectTransform.FracDir(0.05f, 0.72f, 0.4f, 0.94f);
            LanguageButton(panel, "ar", "العربية", 0.42f, 0.67f);
            LanguageButton(panel, "en", "English", 0.7f, 0.95f);

            // Sound
            Ui.Label("Sound", panel, Loc.Get("sound"), 34, Theme.Ink).rectTransform.FracDir(0.05f, 0.44f, 0.6f, 0.66f);
            bool soundOn = Store.SoundOn;
            Ui.TextButton("Sound Toggle", panel, Loc.Get(soundOn ? "on" : "off"), soundOn ? Theme.Success : Theme.InkSoft, () =>
            {
                Store.SoundOn = !soundOn;
                App.I.Sfx.Play(Sfx.Tap);
                Show(true, null);
            }, 32).Root.FracDir(0.7f, 0.46f, 0.95f, 0.64f);

            // Reset: the first tap arms the button, the second one confirms.
            string resetLabel = resetArmed ? Loc.Get("resetConfirm") : Loc.Get("reset");
            Ui.TextButton("Reset", panel, resetLabel, Theme.Danger, () =>
            {
                App.I.Sfx.Play(Sfx.Tap);
                if (!resetArmed)
                {
                    resetArmed = true;
                    Show(true, null);
                    return;
                }
                resetArmed = false;
                Store.ResetProgress(App.I.Catalog);
                Show(true, Loc.Get("resetDone"));
            }, 30).Root.FracDir(0.05f, 0.18f, 0.6f, 0.36f);

            if (!string.IsNullOrEmpty(message))
            {
                Ui.Label("Message", panel, message, 28, Theme.Success).rectTransform.FracDir(0.05f, 0.02f, 0.95f, 0.15f);
            }
        }

        private static void LanguageButton(RectTransform panel, string code, string label, float x0, float x1)
        {
            bool current = Loc.Language == code;
            Ui.TextButton("Language " + code, panel, label, current ? Theme.Primary : Theme.InkSoft, () =>
            {
                App.I.Sfx.Play(Sfx.Tap);
                App.I.SetLanguage(code);
                resetArmed = false;
                Show(true, null);
            }, 32).Root.FracDir(x0, 0.74f, x1, 0.92f);
        }
    }
}
