using System;
using System.Collections.Generic;

namespace Nujoom
{
    /// <summary>
    /// A tiny built-in test suite for the pure logic (game rules, Arabic
    /// shaping, content). No test framework needed.
    ///
    /// In Unity: menu  Nujoom > Run Self Check  (results appear in the Console).
    /// It also runs automatically at startup in the Editor.
    /// </summary>
    public static class SelfCheck
    {
        /// <summary>Runs every check and returns the failures (empty = all good).</summary>
        public static List<string> RunAll(Catalog catalog, out int checks)
        {
            var failures = new List<string>();
            int count = 0;
            Action<bool, string> check = (condition, description) =>
            {
                count++;
                if (!condition) failures.Add(description);
            };

            CheckStars(check);
            CheckChoice(check);
            CheckMemory(check);
            CheckMatch(check);
            CheckArabic(check);
            if (catalog != null) CheckCatalog(catalog, check);

            checks = count;
            return failures;
        }

        private static List<LearningItem> MakeItems(int count)
        {
            var items = new List<LearningItem>();
            for (int i = 0; i < count; i++)
            {
                items.Add(new LearningItem { id = "item" + i });
            }
            return items;
        }

        private static void CheckStars(Action<bool, string> check)
        {
            check(Stars.For(0, 6) == 3, "stars: perfect run gives 3");
            check(Stars.For(1, 6) == 2, "stars: one mistake gives 2");
            check(Stars.For(3, 6) == 2, "stars: half mistakes still gives 2");
            check(Stars.For(4, 6) == 1, "stars: many mistakes gives 1");
            check(Stars.For(99, 6) == 1, "stars: never below 1");
        }

        private static void CheckChoice(Action<bool, string> check)
        {
            for (int seed = 0; seed < 40; seed++)
            {
                var session = new ChoiceSession(MakeItems(5), 8, new Random(seed));
                check(session.Rounds.Count == 8, "choice: builds the requested rounds");
                for (int i = 0; i < session.Rounds.Count; i++)
                {
                    ChoiceRound round = session.Rounds[i];
                    check(round.Options.Count == 3, "choice: three options");
                    check(round.Options.Contains(round.Target), "choice: target is among the options");
                    check(new HashSet<LearningItem>(round.Options).Count == round.Options.Count, "choice: options are unique");
                    if (i > 0) check(round.Target != session.Rounds[i - 1].Target, "choice: no target twice in a row");
                }
            }

            var two = new ChoiceSession(MakeItems(2), 4, new Random(1));
            check(two.Round.Options.Count == 2, "choice: two items give two options");

            // Wrong pick, repeated wrong pick, then the right one.
            var game = new ChoiceSession(MakeItems(4), 3, new Random(1));
            LearningItem wrong = game.Round.Options.Find(o => o != game.Round.Target);
            check(game.Pick(wrong) == Outcome.Wrong, "choice: wrong pick is reported");
            check(game.Pick(wrong) == Outcome.Ignored, "choice: same wrong pick is ignored");
            check(game.Mistakes == 1, "choice: mistake counted once");
            check(game.Pick(game.Round.Target) == Outcome.RoundDone, "choice: right pick ends the round");
            check(game.Pick(game.Round.Target) == Outcome.Ignored, "choice: picks ignored while celebrating");
            game.NextRound();
            check(game.Index == 1 && !game.Solved && game.Eliminated.Count == 0, "choice: next round starts clean");

            // A perfect game.
            var perfect = new ChoiceSession(MakeItems(4), 3, new Random(2));
            Outcome last = Outcome.Ignored;
            for (int guard = 0; guard < 10 && !perfect.Finished; guard++)
            {
                last = perfect.Pick(perfect.Round.Target);
                perfect.NextRound();
            }
            check(last == Outcome.Finished && perfect.Finished, "choice: perfect game finishes");
            check(perfect.StarsEarned == 3, "choice: perfect game earns 3 stars");
            check(perfect.Index == 2, "choice: index stays on the last round");
        }

        private static void CheckMemory(Action<bool, string> check)
        {
            var big = new MemorySession(MakeItems(9), new Random(3));
            check(big.Cards.Count == 12, "memory: capped at 6 pairs");
            var counts = new Dictionary<string, int>();
            foreach (LearningItem card in big.Cards)
            {
                int n;
                counts.TryGetValue(card.id, out n);
                counts[card.id] = n + 1;
            }
            bool allPairs = true;
            foreach (int n in counts.Values) allPairs &= n == 2;
            check(counts.Count == 6 && allPairs, "memory: exactly two cards per item");

            var game = new MemorySession(MakeItems(3), new Random(2));
            var positions = new Dictionary<string, List<int>>();
            for (int i = 0; i < game.Cards.Count; i++)
            {
                if (!positions.ContainsKey(game.Cards[i].id)) positions[game.Cards[i].id] = new List<int>();
                positions[game.Cards[i].id].Add(i);
            }
            var pairs = new List<List<int>>(positions.Values);

            check(game.Flip(pairs[0][0]) == Outcome.Correct, "memory: first card turns over");
            check(game.Flip(pairs[0][0]) == Outcome.Ignored, "memory: same card is ignored");
            check(game.Flip(pairs[1][0]) == Outcome.Wrong, "memory: different cards are a mismatch");
            check(game.WaitingToHide, "memory: mismatch stays on show");
            check(game.Flip(pairs[2][0]) == Outcome.Ignored, "memory: no flipping during a mismatch");
            game.HideMismatch();
            check(game.FaceUp.Count == 0 && game.Mistakes == 1, "memory: mismatch hidden and counted");

            Outcome last = Outcome.Ignored;
            foreach (List<int> pair in pairs)
            {
                game.Flip(pair[0]);
                last = game.Flip(pair[1]);
            }
            check(last == Outcome.Finished && game.Finished, "memory: finding every pair finishes");
            check(game.Matched.Count == 6, "memory: all cards matched");
        }

        private static void CheckMatch(Action<bool, string> check)
        {
            for (int count = 2; count <= 10; count++)
            {
                var session = new MatchSession(MakeItems(count), new Random(count));
                var used = new HashSet<string>();
                foreach (MatchRound round in session.Rounds)
                {
                    check(round.Sources.Count >= 2, "match: no single-piece round (" + count + " items)");
                    check(round.Sources.Count == round.Targets.Count, "match: same pieces and targets");
                    foreach (LearningItem item in round.Sources) used.Add(item.id);
                }
                check(used.Count == count && session.TotalPieces == count, "match: every item used once (" + count + ")");
            }

            var game = new MatchSession(MakeItems(5), new Random(3));
            MatchRound first = game.Round;
            check(game.Drop(first.Sources[0].id, first.Sources[1].id) == Outcome.Wrong, "match: wrong drop is reported");
            check(game.Mistakes == 1 && game.Matched.Count == 0, "match: wrong drop counted, nothing placed");

            Outcome last = Outcome.Ignored;
            for (int guard = 0; guard < 10 && !game.Finished; guard++)
            {
                foreach (LearningItem item in new List<LearningItem>(game.Round.Sources))
                {
                    last = game.Drop(item.id, item.id);
                }
                game.NextRound();
            }
            check(last == Outcome.Finished && game.Finished, "match: placing every piece finishes");
            check(game.StarsEarned == 2, "match: one mistake in five pieces gives 2 stars");
        }

        private static void CheckArabic(Action<bool, string> check)
        {
            check(ArabicShaper.Fix("Hello 123") == "Hello 123", "arabic: Latin text is untouched");
            check(!ArabicShaper.HasArabic("ABC") && ArabicShaper.HasArabic("أ"), "arabic: detection");

            // قطة = qaf (initial) + tah (medial) + teh marbuta (final)
            check(ArabicShaper.Shape("قطة") == "ﻗﻄﺔ", "arabic: initial, medial, final forms");
            // أب = alef-hamza never joins forward, so both letters are isolated
            check(ArabicShaper.Shape("أب") == "ﺃﺏ", "arabic: non-joining letter isolates the next");
            // سلام = seen (initial) + lam-alef ligature (final) + meem (isolated)
            check(ArabicShaper.Shape("سلام") == "ﺳﻼﻡ", "arabic: lam-alef ligature");
            // لا alone = isolated ligature
            check(ArabicShaper.Shape("لا") == "ﻻ", "arabic: isolated lam-alef");
            // Diacritics are removed: أَلِف -> ألف
            check(ArabicShaper.Shape("أَلِف") == ArabicShaper.Shape("ألف"), "arabic: diacritics removed");
            // Hamza on the line never joins: ماء
            check(ArabicShaper.Shape("ماء") == "ﻣﺎﺀ", "arabic: hamza stays isolated");

            // Visual order: letters reversed.
            check(ArabicShaper.Fix("قطة") == "ﺔﻄﻗ", "arabic: word is reversed for display");
            // Numbers keep their order and swap sides with the words: "5 نجمة"
            string stars = ArabicShaper.Fix("5 نجمة");
            check(stars.EndsWith(" 5") && stars.Length == 6, "arabic: number moves to the right end");
            // "3 × 4" inside Arabic stays "3 × 4".
            string question = ArabicShaper.Fix("كم 3 × 4؟");
            check(question.Contains("3 × 4"), "arabic: expression keeps its order");
            check(question[0] == '؟', "arabic: question mark ends up on the left");
            // Two-digit numbers are not reversed.
            check(ArabicShaper.Fix("نجوم 12").StartsWith("12"), "arabic: multi-digit number intact");
        }

        private static void CheckCatalog(Catalog catalog, Action<bool, string> check)
        {
            List<string> problems = catalog.Validate();
            check(problems.Count == 0, "catalog: " + string.Join("; ", problems.ToArray()));
            foreach (Topic topic in catalog.topics)
            {
                foreach (Activity activity in topic.activities)
                {
                    bool builds = true;
                    try
                    {
                        var random = new Random(1);
                        if (activity.type == "choice") new ChoiceSession(topic.items, Math.Max(1, activity.rounds), random);
                        else if (activity.type == "memory") new MemorySession(topic.items, random);
                        else new MatchSession(topic.items, random);
                    }
                    catch (Exception)
                    {
                        builds = false;
                    }
                    check(builds, "catalog: activity '" + activity.id + "' can start");
                }
            }
        }
    }
}
