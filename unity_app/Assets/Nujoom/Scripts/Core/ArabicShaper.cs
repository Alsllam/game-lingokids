using System.Collections.Generic;
using System.Text;

namespace Nujoom
{
    /// <summary>
    /// Makes Arabic text display correctly in Unity's legacy UI Text.
    ///
    /// Unity's Text component draws characters one by one, left to right, and
    /// does not join Arabic letters. Without help, "قطة" appears as three
    /// separate letters in the wrong order. This class fixes both problems:
    ///   1. Shaping: each letter is replaced by its isolated / initial /
    ///      medial / final glyph (Unicode "Presentation Forms-B").
    ///   2. Ordering: the result is reversed so a left-to-right renderer
    ///      shows it right-to-left, while numbers and Latin words keep
    ///      their own order.
    ///
    /// It is pure C# (no UnityEngine), so it can be tested anywhere.
    /// Limits: single-line text only, and diacritics (tashkeel) are removed.
    /// The font must contain the Presentation Forms-B glyphs.
    /// </summary>
    public static class ArabicShaper
    {
        // For each base letter: the code of its ISOLATED form and how many
        // forms it has. 4 forms = isolated, final, initial, medial (in that
        // order, consecutive codes). 2 forms = isolated, final: such letters
        // never join to the letter after them.
        private struct Forms
        {
            public readonly char Isolated;
            public readonly int Count;

            public Forms(int isolated, int count)
            {
                Isolated = (char)isolated;
                Count = count;
            }
        }

        private static readonly Dictionary<char, Forms> Table = new Dictionary<char, Forms>
        {
            { 'ء', new Forms(0xFE80, 1) }, // hamza
            { 'آ', new Forms(0xFE81, 2) }, // alef with madda
            { 'أ', new Forms(0xFE83, 2) }, // alef with hamza above
            { 'ؤ', new Forms(0xFE85, 2) }, // waw with hamza
            { 'إ', new Forms(0xFE87, 2) }, // alef with hamza below
            { 'ئ', new Forms(0xFE89, 4) }, // yeh with hamza
            { 'ا', new Forms(0xFE8D, 2) }, // alef
            { 'ب', new Forms(0xFE8F, 4) }, // beh
            { 'ة', new Forms(0xFE93, 2) }, // teh marbuta
            { 'ت', new Forms(0xFE95, 4) }, // teh
            { 'ث', new Forms(0xFE99, 4) }, // theh
            { 'ج', new Forms(0xFE9D, 4) }, // jeem
            { 'ح', new Forms(0xFEA1, 4) }, // hah
            { 'خ', new Forms(0xFEA5, 4) }, // khah
            { 'د', new Forms(0xFEA9, 2) }, // dal
            { 'ذ', new Forms(0xFEAB, 2) }, // thal
            { 'ر', new Forms(0xFEAD, 2) }, // reh
            { 'ز', new Forms(0xFEAF, 2) }, // zain
            { 'س', new Forms(0xFEB1, 4) }, // seen
            { 'ش', new Forms(0xFEB5, 4) }, // sheen
            { 'ص', new Forms(0xFEB9, 4) }, // sad
            { 'ض', new Forms(0xFEBD, 4) }, // dad
            { 'ط', new Forms(0xFEC1, 4) }, // tah
            { 'ظ', new Forms(0xFEC5, 4) }, // zah
            { 'ع', new Forms(0xFEC9, 4) }, // ain
            { 'غ', new Forms(0xFECD, 4) }, // ghain
            { 'ف', new Forms(0xFED1, 4) }, // feh
            { 'ق', new Forms(0xFED5, 4) }, // qaf
            { 'ك', new Forms(0xFED9, 4) }, // kaf
            { 'ل', new Forms(0xFEDD, 4) }, // lam
            { 'م', new Forms(0xFEE1, 4) }, // meem
            { 'ن', new Forms(0xFEE5, 4) }, // noon
            { 'ه', new Forms(0xFEE9, 4) }, // heh
            { 'و', new Forms(0xFEED, 2) }, // waw
            { 'ى', new Forms(0xFEEF, 2) }, // alef maksura
            { 'ي', new Forms(0xFEF1, 4) }, // yeh
        };

        // lam + alef variants merge into one ligature glyph (isolated form;
        // the final form is the next code).
        private static readonly Dictionary<char, char> LamAlef = new Dictionary<char, char>
        {
            { 'آ', 'ﻵ' },
            { 'أ', 'ﻷ' },
            { 'إ', 'ﻹ' },
            { 'ا', 'ﻻ' },
        };

        private const char Lam = 'ل';

        /// <summary>True when the text has at least one Arabic letter.</summary>
        public static bool HasArabic(string text)
        {
            if (string.IsNullOrEmpty(text)) return false;
            foreach (char c in text)
            {
                if (IsArabicLetter(c)) return true;
            }
            return false;
        }

        /// <summary>Shapes and reorders one line for a left-to-right renderer.</summary>
        public static string Fix(string text)
        {
            if (!HasArabic(text)) return text;
            return Reorder(Shape(text));
        }

        /// <summary>Step 1: choose the right glyph for every letter (logical order).</summary>
        public static string Shape(string text)
        {
            string clean = StripDiacritics(text);
            var output = new StringBuilder(clean.Length);
            for (int i = 0; i < clean.Length; i++)
            {
                char c = clean[i];
                Forms forms;
                if (!Table.TryGetValue(c, out forms))
                {
                    output.Append(c);
                    continue;
                }

                bool joinsPrevious = i > 0 && JoinsForward(clean[i - 1]);

                // lam followed by alef becomes a single ligature.
                char ligature;
                if (c == Lam && i + 1 < clean.Length && LamAlef.TryGetValue(clean[i + 1], out ligature))
                {
                    output.Append(joinsPrevious ? (char)(ligature + 1) : ligature);
                    i++;
                    continue;
                }

                bool joinsNext = forms.Count == 4 && i + 1 < clean.Length && JoinsBackward(clean[i + 1]);

                int offset;
                if (joinsPrevious && joinsNext) offset = 3;      // medial
                else if (joinsPrevious && forms.Count >= 2) offset = 1; // final
                else if (joinsNext) offset = 2;                  // initial
                else offset = 0;                                 // isolated
                output.Append((char)(forms.Isolated + offset));
            }
            return output.ToString();
        }

        /// <summary>
        /// Step 2: visual order. Right-to-left runs are reversed; numbers and
        /// Latin words stay readable; the runs themselves swap sides.
        /// </summary>
        public static string Reorder(string shaped)
        {
            // Mark every character as left-to-right (true) or not.
            int n = shaped.Length;
            var ltr = new bool[n];
            for (int i = 0; i < n; i++) ltr[i] = IsStrongLtr(shaped[i]);

            // A neutral character (space, punctuation) between two
            // left-to-right characters belongs to that run: "3 x 4".
            for (int i = 0; i < n; i++)
            {
                if (ltr[i] || IsRtl(shaped[i])) continue;
                int before = i - 1;
                while (before >= 0 && !ltr[before] && !IsRtl(shaped[before])) before--;
                int after = i + 1;
                while (after < n && !IsStrongLtr(shaped[after]) && !IsRtl(shaped[after])) after++;
                bool ltrBefore = before >= 0 && ltr[before];
                bool ltrAfter = after < n && IsStrongLtr(shaped[after]);
                ltr[i] = ltrBefore && ltrAfter;
            }

            // Walk from the end; emit RTL characters one by one (reversed) and
            // LTR runs as whole blocks (kept in order).
            var output = new StringBuilder(n);
            int index = n - 1;
            while (index >= 0)
            {
                if (!ltr[index])
                {
                    output.Append(Mirror(shaped[index]));
                    index--;
                    continue;
                }
                int end = index;
                while (index >= 0 && ltr[index]) index--;
                output.Append(shaped, index + 1, end - index);
            }
            return output.ToString();
        }

        private static string StripDiacritics(string text)
        {
            var output = new StringBuilder(text.Length);
            foreach (char c in text)
            {
                bool diacritic = (c >= 'ً' && c <= 'ْ') || c == 'ٰ' || c == 'ـ';
                if (!diacritic) output.Append(c);
            }
            return output.ToString();
        }

        // Can this letter connect to the letter that follows it?
        private static bool JoinsForward(char c)
        {
            Forms forms;
            return Table.TryGetValue(c, out forms) && forms.Count == 4;
        }

        // Can this letter connect to the letter before it?
        private static bool JoinsBackward(char c)
        {
            Forms forms;
            return Table.TryGetValue(c, out forms) && forms.Count >= 2;
        }

        private static bool IsArabicLetter(char c)
        {
            return (c >= 'ء' && c <= 'ي') || (c >= 'ﹰ' && c <= 'ﻼ');
        }

        private static bool IsRtl(char c)
        {
            // Letters, presentation forms, and the Arabic comma / question mark.
            return IsArabicLetter(c) || c == '،' || c == '؟' || c == '؛';
        }

        private static bool IsStrongLtr(char c)
        {
            if (c >= '0' && c <= '9') return true;
            if (c >= '٠' && c <= '٩') return true; // Arabic-Indic digits read left to right
            return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
        }

        private static char Mirror(char c)
        {
            switch (c)
            {
                case '(': return ')';
                case ')': return '(';
                case '[': return ']';
                case ']': return '[';
                default: return c;
            }
        }
    }
}
