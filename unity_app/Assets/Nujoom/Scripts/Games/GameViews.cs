using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Nujoom
{
    // The three game templates. Each "view" builds its UI, forwards touches
    // to a session object from GameEngines.cs (the rules), and animates the
    // answer. No rule is decided in this file.

    // ------------------------------------------------------------------
    // Template 1: tap the right picture
    // ------------------------------------------------------------------
    public class ChoiceView
    {
        private readonly GameScreen host;
        private readonly ChoiceSession session;
        private readonly RectTransform body;
        private readonly Text prompt;
        private readonly Text counter;

        // Clue for a child who is stuck: after a pause the right card bounces.
        private const float HintAfterSeconds = 7f;
        private readonly Dictionary<string, Card> optionCards = new Dictionary<string, Card>();
        private int hintTicket;

        public ChoiceView(GameScreen host, RectTransform area, Topic topic, Activity activity)
        {
            this.host = host;
            session = new ChoiceSession(topic.items, Math.Max(1, activity.rounds), new System.Random());
            prompt = host.MakePrompt(area, "");
            counter = host.MakeCounter(area);
            body = Ui.Node("Options", area).Frac(0f, 0f, 1f, 0.83f);
            ShowRound();
        }

        private void ShowRound()
        {
            GameScreen.Clear(body);
            optionCards.Clear();
            ChoiceRound round = session.Round;
            Ui.SetText(prompt, Loc.Format("findPrompt", round.Target.name.Of(Loc.Language)));
            host.Prompt();
            ScheduleHint();
            Ui.SetText(counter, (session.Index + 1) + " / " + session.Rounds.Count);

            int count = round.Options.Count;
            for (int i = 0; i < count; i++)
            {
                LearningItem option = round.Options[i]; // a fresh variable per loop turn, for the lambda below
                RectTransform slot = Ui.Node("Slot " + i, body).Frac((float)i / count, 0.04f, (float)(i + 1) / count, 0.96f);
                RectTransform square = Ui.SquareIn("Option", slot, 14f);
                Card card = Ui.MakeCard("Card", square, Theme.Card);
                card.Root.Fill();
                Visuals.Build(card.Face, option.visual, 16f);
                Tween.PopIn(card.Root, 0.09f * i);
                Ui.OnTap(card.Root, () => Pick(option, card));
                optionCards[option.id] = card;
            }
        }

        // Every call makes older scheduled hints stale, so any activity
        // (a tap, a new round) pushes the clue further away.
        private void ScheduleHint()
        {
            int ticket = ++hintTicket;
            Tween.Delay(body.gameObject, HintAfterSeconds, () =>
            {
                if (ticket != hintTicket || session.Solved || session.Finished) return;
                Card target;
                if (optionCards.TryGetValue(session.Round.Target.id, out target))
                {
                    Tween.Punch(target.Root, 0.22f, 0.7f);
                    host.Prompt();
                }
                ScheduleHint(); // keep nudging until the child answers
            });
        }

        private void Pick(LearningItem option, Card card)
        {
            Outcome outcome = session.Pick(option);
            if (outcome == Outcome.Ignored) return;

            if (outcome == Outcome.Wrong)
            {
                host.Wrong();
                ScheduleHint();
                Tween.Shake(card.Root);
                // Fade the ruled-out card and stop it reacting to taps.
                var group = card.Root.gameObject.AddComponent<CanvasGroup>();
                Tween.FadeTo(group, 0.35f);
                card.Root.GetComponent<PressButton>().Interactable = false;
                return;
            }

            hintTicket++; // answered: cancel any pending hint
            card.SetColor(Theme.Success);
            Tween.Punch(card.Root);
            host.Right();
            bool finished = outcome == Outcome.Finished;
            Tween.Delay(body.gameObject, 1.1f, () =>
            {
                if (finished)
                {
                    host.Finish(session.StarsEarned);
                    return;
                }
                session.NextRound();
                ShowRound();
            });
        }
    }

    // ------------------------------------------------------------------
    // Template 2: memory pairs
    // ------------------------------------------------------------------
    public class MemoryView
    {
        private class CardView
        {
            public RectTransform Root;
            public Card Front;
            public GameObject Back;
        }

        private readonly GameScreen host;
        private readonly MemorySession session;
        private readonly List<CardView> cards = new List<CardView>();
        private readonly RectTransform body;

        public MemoryView(GameScreen host, RectTransform area, Topic topic)
        {
            this.host = host;
            session = new MemorySession(topic.items, new System.Random());
            host.MakePrompt(area, Loc.Get("memoryPrompt"));
            body = Ui.Node("Cards", area).Frac(0f, 0f, 1f, 0.84f);

            int count = session.Cards.Count;
            int columns = count <= 6 ? 3 : count <= 8 ? 4 : count == 10 ? 5 : 4;
            int rows = (count + columns - 1) / columns;
            for (int i = 0; i < count; i++)
            {
                int index = i;
                int column = i % columns;
                int row = i / columns;
                RectTransform cell = Ui.Node("Cell " + i, body).Frac(
                    (float)column / columns, 1f - (float)(row + 1) / rows,
                    (float)(column + 1) / columns, 1f - (float)row / rows);
                RectTransform square = Ui.SquareIn("Card", cell, 8f);

                var view = new CardView { Root = square };
                view.Front = Ui.MakeCard("Front", square, Theme.Card);
                view.Front.Root.Fill();
                Visuals.Build(view.Front.Face, session.Cards[i].visual, 10f);
                view.Front.Root.gameObject.SetActive(false);

                Card back = Ui.MakeCard("Back", square, Theme.Primary);
                back.Root.Fill();
                Image star = Ui.Img("Star", back.Face, Shapes.Star, Theme.Star);
                star.rectTransform.Frac(0.28f, 0.28f, 0.72f, 0.72f);
                view.Back = back.Root.gameObject;

                cards.Add(view);
                Tween.PopIn(square, 0.035f * i);
                Ui.OnTap(square, () => Flip(index));
            }
        }

        private void Flip(int index)
        {
            int firstIndex = session.FaceUp.Count == 1 ? session.FaceUp[0] : -1;
            Outcome outcome = session.Flip(index);
            if (outcome == Outcome.Ignored) return;

            App.I.Sfx.Play(Sfx.Flip);
            Turn(index, true);
            if (outcome == Outcome.Correct) return; // only the first card of a pair

            if (outcome == Outcome.Wrong)
            {
                Tween.Delay(body.gameObject, 0.35f, host.Wrong);
                Tween.Delay(body.gameObject, 1.0f, () =>
                {
                    Turn(firstIndex, false);
                    Turn(index, false);
                    session.HideMismatch();
                });
                return;
            }

            // A pair was found.
            bool finished = outcome == Outcome.Finished;
            Tween.Delay(body.gameObject, 0.35f, () =>
            {
                host.Right();
                foreach (int matched in new[] { firstIndex, index })
                {
                    cards[matched].Front.SetColor(Theme.Lighter(Theme.Success, 0.7f));
                    Tween.Punch(cards[matched].Root);
                }
            });
            if (finished) Tween.Delay(body.gameObject, 1.2f, () => host.Finish(session.StarsEarned));
        }

        private void Turn(int index, bool faceUp)
        {
            CardView view = cards[index];
            Tween.Flip(view.Root, () =>
            {
                view.Front.Root.gameObject.SetActive(faceUp);
                view.Back.SetActive(!faceUp);
            });
        }
    }

    // ------------------------------------------------------------------
    // Template 3: drag each piece onto its partner
    // ------------------------------------------------------------------
    public class MatchView
    {
        private readonly GameScreen host;
        private readonly MatchSession session;
        private readonly RectTransform body;
        private readonly Text counter;
        private readonly Dictionary<string, Card> targets = new Dictionary<string, Card>();

        public MatchView(GameScreen host, RectTransform area, Topic topic)
        {
            this.host = host;
            session = new MatchSession(topic.items, new System.Random());
            host.MakePrompt(area, Loc.Get("matchPrompt"));
            counter = host.MakeCounter(area);
            body = Ui.Node("Board", area).Frac(0f, 0f, 1f, 0.84f);
            ShowRound();
        }

        private void ShowRound()
        {
            GameScreen.Clear(body);
            targets.Clear();
            MatchRound round = session.Round;
            Ui.SetText(counter, (session.Index + 1) + " / " + session.Rounds.Count);
            int count = round.Sources.Count;

            // Targets are created first so the dragged pieces draw on top of them.
            RectTransform targetRow = Ui.Node("Targets", body).Frac(0f, 0f, 1f, 0.48f);
            for (int i = 0; i < count; i++)
            {
                LearningItem item = round.Targets[i];
                RectTransform slot = Ui.Node("Slot " + i, targetRow).Frac((float)i / count, 0f, (float)(i + 1) / count, 1f);
                RectTransform square = Ui.SquareIn("Target", slot, 10f);
                Card card = Ui.MakeCard("Card", square, Theme.Lighter(Theme.SkyTop, 0.55f));
                card.Root.Fill();
                Visuals.Build(card.Face, item.PairOrLabel, 14f);
                targets[item.id] = card;
            }

            RectTransform sourceRow = Ui.Node("Pieces", body).Frac(0f, 0.52f, 1f, 1f);
            for (int i = 0; i < count; i++)
            {
                LearningItem item = round.Sources[i];
                RectTransform slot = Ui.Node("Slot " + i, sourceRow).Frac((float)i / count, 0f, (float)(i + 1) / count, 1f);
                RectTransform square = Ui.SquareIn("Piece", slot, 10f);
                Card card = Ui.MakeCard("Card", square, Theme.Card);
                card.Root.Fill();
                Visuals.Build(card.Face, item.visual, 14f);
                Tween.PopIn(card.Root, 0.08f * i);

                var piece = card.Root.gameObject.AddComponent<DragPiece>();
                piece.Item = item;
                piece.Slot = slot;
                piece.OnDropped = Dropped;
            }
        }

        // Called by a piece when the finger lifts. screenPoint is in pixels.
        private void Dropped(DragPiece piece, Vector2 screenPoint)
        {
            string targetId = null;
            foreach (KeyValuePair<string, Card> entry in targets)
            {
                // The camera is null because the canvas is a screen-space overlay.
                if (RectTransformUtility.RectangleContainsScreenPoint(entry.Value.Root, screenPoint, null))
                {
                    targetId = entry.Key;
                    break;
                }
            }

            Outcome outcome = targetId == null ? Outcome.Ignored : session.Drop(piece.Item.id, targetId);
            if (outcome == Outcome.Ignored)
            {
                piece.ReturnHome();
                return;
            }
            if (outcome == Outcome.Wrong)
            {
                host.Wrong();
                Tween.Shake(targets[targetId].Root);
                piece.ReturnHome();
                return;
            }

            // Correct: the piece settles into the corner of its target.
            Card target = targets[targetId];
            target.SetColor(Theme.Lighter(Theme.Success, 0.7f));
            RectTransform badge = Ui.Node("Placed", target.Face).Frac(0.56f, 0.56f, 0.98f, 0.98f);
            Ui.Img("Circle", badge, Shapes.Circle, Theme.Card).rectTransform.Fill();
            Visuals.Build(badge, piece.Item.visual, 6f);
            Tween.PopIn(badge);
            Tween.Punch(target.Root);
            UnityEngine.Object.Destroy(piece.gameObject);
            host.Right();

            if (outcome == Outcome.Correct) return;
            bool finished = outcome == Outcome.Finished;
            Tween.Delay(body.gameObject, 1.0f, () =>
            {
                if (finished)
                {
                    host.Finish(session.StarsEarned);
                    return;
                }
                session.NextRound();
                ShowRound();
            });
        }
    }

    /// <summary>
    /// Lets the player drag its object with a finger or the mouse. Unity
    /// calls the three methods because of the drag interfaces.
    /// </summary>
    public class DragPiece : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        [NonSerialized] public LearningItem Item;
        [NonSerialized] public RectTransform Slot;
        [NonSerialized] public Action<DragPiece, Vector2> OnDropped;

        private RectTransform rect;
        private Vector2 home;
        private bool dragging;

        private void Awake()
        {
            rect = (RectTransform)transform;
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            dragging = true;
            home = Vector2.zero;
            if (Slot != null) Slot.SetAsLastSibling(); // draw above the other pieces
            Tween.ScaleTo(rect, 1.08f, 0.1f);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (!dragging) return;
            // eventData.delta is in screen pixels; the canvas may be scaled.
            rect.anchoredPosition += eventData.delta / App.I.Canvas.scaleFactor;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (!dragging) return;
            dragging = false;
            if (OnDropped != null) OnDropped(this, eventData.position);
        }

        public void ReturnHome()
        {
            Tween.ScaleTo(rect, 1f, 0.15f);
            Tween.MoveTo(rect, home, 0.25f);
        }
    }
}
