using System;
using System.Collections.Generic;

namespace Nujoom
{
    // Pure game rules: no UnityEngine, no UI, no sound. Each "session" class
    // is a small state machine. The screen calls a method (Pick, Flip, Drop),
    // reads the answer, and decides what to animate. Because nothing here
    // depends on Unity, the same rules are checked by SelfCheck.cs.

    /// <summary>What happened after a player action.</summary>
    public enum Outcome
    {
        Ignored,   // nothing to do (already solved, same card, ...)
        Wrong,
        Correct,   // right, and the round continues or a new one follows
        RoundDone, // right, and this was the last piece of the round
        Finished,  // right, and the whole activity is complete
    }

    public static class Stars
    {
        /// <summary>
        /// 3 stars for a perfect run, 2 when mistakes are at most half the
        /// number of questions, otherwise 1. Finishing always earns a star.
        /// </summary>
        public static int For(int mistakes, int questions)
        {
            if (mistakes <= 0) return 3;
            if (mistakes * 2 <= questions) return 2;
            return 1;
        }
    }

    public static class Shuffle
    {
        /// <summary>Fisher-Yates shuffle; returns a new list.</summary>
        public static List<T> Of<T>(IEnumerable<T> source, Random random)
        {
            var list = new List<T>(source);
            for (int i = list.Count - 1; i > 0; i--)
            {
                int j = random.Next(i + 1);
                T swap = list[i];
                list[i] = list[j];
                list[j] = swap;
            }
            return list;
        }
    }

    // ------------------------------------------------------------------
    // Template 1: choice ("find it")
    // ------------------------------------------------------------------

    public class ChoiceRound
    {
        public LearningItem Target;
        public List<LearningItem> Options;
    }

    public class ChoiceSession
    {
        public readonly List<ChoiceRound> Rounds = new List<ChoiceRound>();
        public readonly HashSet<string> Eliminated = new HashSet<string>();
        public int Index { get; private set; }
        public int Mistakes { get; private set; }
        public bool Solved { get; private set; }
        public bool Finished { get; private set; }

        public ChoiceRound Round
        {
            get { return Rounds[Index]; }
        }

        public int StarsEarned
        {
            get { return Stars.For(Mistakes, Rounds.Count); }
        }

        /// <summary>
        /// Targets cycle through every item before repeating, and the same
        /// target never comes twice in a row.
        /// </summary>
        public ChoiceSession(List<LearningItem> items, int rounds, Random random, int optionCount = 3)
        {
            if (items.Count < 2) throw new ArgumentException("a choice game needs at least 2 items");
            int options = Math.Min(optionCount, items.Count);
            var queue = new List<LearningItem>();
            LearningItem previous = null;
            for (int i = 0; i < rounds; i++)
            {
                if (queue.Count == 0)
                {
                    queue = Shuffle.Of(items, random);
                    if (queue[0] == previous && queue.Count > 1)
                    {
                        queue.Add(queue[0]);
                        queue.RemoveAt(0);
                    }
                }
                LearningItem target = queue[0];
                queue.RemoveAt(0);
                previous = target;

                var others = new List<LearningItem>();
                foreach (LearningItem item in items)
                {
                    if (item != target) others.Add(item);
                }
                others = Shuffle.Of(others, random);
                var roundOptions = new List<LearningItem> { target };
                roundOptions.AddRange(others.GetRange(0, options - 1));
                Rounds.Add(new ChoiceRound { Target = target, Options = Shuffle.Of(roundOptions, random) });
            }
        }

        public Outcome Pick(LearningItem item)
        {
            if (Solved || Finished || Eliminated.Contains(item.id)) return Outcome.Ignored;
            if (item.id != Round.Target.id)
            {
                Eliminated.Add(item.id);
                Mistakes++;
                return Outcome.Wrong;
            }
            Solved = true;
            if (Index + 1 >= Rounds.Count)
            {
                Finished = true;
                return Outcome.Finished;
            }
            return Outcome.RoundDone;
        }

        /// <summary>Call after celebrating a solved round.</summary>
        public void NextRound()
        {
            if (Finished || !Solved) return;
            Index++;
            Solved = false;
            Eliminated.Clear();
        }
    }

    // ------------------------------------------------------------------
    // Template 2: memory
    // ------------------------------------------------------------------

    public class MemorySession
    {
        /// <summary>The item shown by the card at each position.</summary>
        public readonly List<LearningItem> Cards;
        public readonly HashSet<int> Matched = new HashSet<int>();

        /// <summary>The (at most two) cards currently turned over.</summary>
        public readonly List<int> FaceUp = new List<int>();
        public int Mistakes { get; private set; }
        public bool Finished { get; private set; }

        public int StarsEarned
        {
            get { return Stars.For(Mistakes, Cards.Count); }
        }

        public MemorySession(List<LearningItem> items, Random random, int maxPairs = 6)
        {
            List<LearningItem> chosen = Shuffle.Of(items, random);
            if (chosen.Count > maxPairs) chosen = chosen.GetRange(0, maxPairs);
            var faces = new List<LearningItem>(chosen);
            faces.AddRange(chosen);
            Cards = Shuffle.Of(faces, random);
        }

        public bool IsFaceUp(int index)
        {
            return Matched.Contains(index) || FaceUp.Contains(index);
        }

        /// <summary>
        /// True while two different cards are on show. The screen must call
        /// HideMismatch() (after a pause) before more cards can be flipped.
        /// </summary>
        public bool WaitingToHide
        {
            get { return FaceUp.Count == 2; }
        }

        public Outcome Flip(int index)
        {
            if (Finished || WaitingToHide || IsFaceUp(index)) return Outcome.Ignored;
            FaceUp.Add(index);
            if (FaceUp.Count < 2) return Outcome.Correct; // first card: just turned over

            if (Cards[FaceUp[0]].id == Cards[FaceUp[1]].id)
            {
                Matched.Add(FaceUp[0]);
                Matched.Add(FaceUp[1]);
                FaceUp.Clear();
                if (Matched.Count == Cards.Count)
                {
                    Finished = true;
                    return Outcome.Finished;
                }
                return Outcome.RoundDone; // a pair was found
            }
            Mistakes++;
            return Outcome.Wrong;
        }

        public void HideMismatch()
        {
            FaceUp.Clear();
        }
    }

    // ------------------------------------------------------------------
    // Template 3: drag-and-drop matching
    // ------------------------------------------------------------------

    public class MatchRound
    {
        public List<LearningItem> Sources;
        public List<LearningItem> Targets;
    }

    public class MatchSession
    {
        public readonly List<MatchRound> Rounds = new List<MatchRound>();
        public readonly HashSet<string> Matched = new HashSet<string>();
        public int Index { get; private set; }
        public int Mistakes { get; private set; }
        public bool Finished { get; private set; }
        public int TotalPieces { get; private set; }

        public MatchRound Round
        {
            get { return Rounds[Index]; }
        }

        public int StarsEarned
        {
            get { return Stars.For(Mistakes, TotalPieces); }
        }

        /// <summary>
        /// Splits the items into rounds of perRound pieces. A last round with
        /// a single piece is merged into the one before, so no round is trivial.
        /// </summary>
        public MatchSession(List<LearningItem> items, Random random, int perRound = 3)
        {
            List<LearningItem> pool = Shuffle.Of(items, random);
            var groups = new List<List<LearningItem>>();
            for (int i = 0; i < pool.Count; i += perRound)
            {
                groups.Add(pool.GetRange(i, Math.Min(perRound, pool.Count - i)));
            }
            if (groups.Count > 1 && groups[groups.Count - 1].Count == 1)
            {
                groups[groups.Count - 2].AddRange(groups[groups.Count - 1]);
                groups.RemoveAt(groups.Count - 1);
            }
            foreach (List<LearningItem> group in groups)
            {
                Rounds.Add(new MatchRound { Sources = Shuffle.Of(group, random), Targets = Shuffle.Of(group, random) });
                TotalPieces += group.Count;
            }
        }

        public Outcome Drop(string sourceId, string targetId)
        {
            if (Finished || Matched.Contains(targetId) || Matched.Contains(sourceId)) return Outcome.Ignored;
            if (sourceId != targetId)
            {
                Mistakes++;
                return Outcome.Wrong;
            }
            Matched.Add(sourceId);
            if (Matched.Count < Round.Sources.Count) return Outcome.Correct;
            if (Index + 1 >= Rounds.Count)
            {
                Finished = true;
                return Outcome.Finished;
            }
            return Outcome.RoundDone;
        }

        /// <summary>Call after celebrating a completed round.</summary>
        public void NextRound()
        {
            if (Finished || Matched.Count < Round.Sources.Count) return;
            Index++;
            Matched.Clear();
        }
    }
}
