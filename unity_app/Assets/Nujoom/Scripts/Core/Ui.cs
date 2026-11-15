using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Nujoom
{
    /// <summary>
    /// Helpers that build Unity UI (uGUI) from code.
    ///
    /// In the Editor you would normally create these objects by hand in the
    /// Hierarchy and save them as Prefabs. Building them in code does exactly
    /// the same thing - press Play and look at the Hierarchy window to see
    /// every object this file creates.
    ///
    /// Positioning uses RectTransform anchors. Anchors are fractions of the
    /// parent: (0,0) is its bottom-left corner and (1,1) its top-right.
    /// </summary>
    public static class Ui
    {
        public static Font Font;

        /// <summary>An empty UI object.</summary>
        public static RectTransform Node(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rect = (RectTransform)go.transform;
            rect.SetParent(parent, false);
            return rect;
        }

        /// <summary>A coloured picture. Leave sprite null for a plain rectangle.</summary>
        public static Image Img(string name, Transform parent, Sprite sprite, Color color, bool blocksTouches = false)
        {
            RectTransform rect = Node(name, parent);
            var image = rect.gameObject.AddComponent<Image>();
            image.sprite = sprite;
            image.color = color;
            image.raycastTarget = blocksTouches;
            if (sprite != null && sprite.border.sqrMagnitude > 0f) image.type = Image.Type.Sliced;
            return image;
        }

        /// <summary>
        /// A line of text that shrinks to fit its box. Arabic is shaped and
        /// reordered here, so callers pass normal strings.
        /// </summary>
        public static Text Label(string name, Transform parent, string content, int maxSize, Color color,
            TextAnchor alignment = TextAnchor.MiddleCenter)
        {
            RectTransform rect = Node(name, parent);
            var text = rect.gameObject.AddComponent<Text>();
            text.font = Font;
            text.fontStyle = FontStyle.Bold;
            text.color = color;
            text.alignment = alignment;
            text.raycastTarget = false;
            // "Wrap" is needed for best-fit to shrink long text to the box
            // width. SetText removes the places where a line could break, so
            // the text still stays on one line (required for shaped Arabic).
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = 8;
            text.resizeTextMaxSize = maxSize;
            text.fontSize = maxSize;
            SetText(text, content);
            return text;
        }

        public static void SetText(Text text, string content)
        {
            // U+00A0 is a space that never breaks a line.
            text.text = ArabicShaper.Fix(content ?? "").Replace(' ', '\u00A0');
        }

        /// <summary>
        /// A raised card: a face on top of a darker "edge" shifted down, which
        /// gives a chunky 3D look. Put children inside Face.
        /// </summary>
        public static Card MakeCard(string name, Transform parent, Color face, Color? edge = null)
        {
            var card = new Card();
            card.Root = Node(name, parent);
            card.Edge = Img("Edge", card.Root, Shapes.Rounded, edge ?? Theme.Darker(face, 0.2f));
            card.Edge.rectTransform.Fill(0, -7, 0, 7);
            card.FaceImage = Img("Face", card.Root, Shapes.Rounded, face, true);
            card.Face = card.FaceImage.rectTransform.Fill();
            return card;
        }

        /// <summary>Makes any UI object tappable, with a squash effect.</summary>
        public static PressButton OnTap(RectTransform target, Action onTap)
        {
            var button = target.gameObject.GetComponent<PressButton>();
            if (button == null) button = target.gameObject.AddComponent<PressButton>();
            button.OnTap = onTap;
            return button;
        }

        /// <summary>A large coloured button with a text label.</summary>
        public static Card TextButton(string name, Transform parent, string label, Color color, Action onTap, int fontSize = 34)
        {
            Card card = MakeCard(name, parent, color);
            Label("Label", card.Face, label, fontSize, Color.white).rectTransform.Fill(14, 6, 14, 6);
            OnTap(card.Root, onTap);
            return card;
        }

        /// <summary>A round white button showing a symbol (a letter or a shape).</summary>
        public static RectTransform RoundButton(string name, Transform parent, string symbol, Action onTap, Color? color = null)
        {
            RectTransform root = Node(name, parent);
            Color face = color ?? Theme.Card;
            Img("Edge", root, Shapes.Circle, Theme.Darker(face, 0.22f)).rectTransform.Fill(0, -5, 0, 5);
            Img("Face", root, Shapes.Circle, face, true).rectTransform.Fill();
            Label("Symbol", root, symbol, 44, color == null ? Theme.Ink : Color.white).rectTransform.Fill(10, 10, 10, 10);
            OnTap(root, onTap);
            return root;
        }

        /// <summary>A child that stays square and as large as fits in its parent.</summary>
        public static RectTransform SquareIn(string name, Transform parent, float padding = 0f)
        {
            RectTransform holder = Node(name + " Holder", parent).Fill(padding, padding, padding, padding);
            RectTransform square = Node(name, holder);
            var fitter = square.gameObject.AddComponent<AspectRatioFitter>();
            fitter.aspectMode = AspectRatioFitter.AspectMode.FitInParent;
            fitter.aspectRatio = 1f;
            return square;
        }

        /// <summary>Three stars showing how many were earned.</summary>
        public static RectTransform StarRow(string name, Transform parent, int earned)
        {
            RectTransform row = Node(name, parent);
            for (int i = 0; i < 3; i++)
            {
                Image star = Img("Star " + (i + 1), row, Shapes.Star, i < earned ? Theme.Star : Theme.StarEmpty);
                star.rectTransform.Frac(i / 3f, 0f, (i + 1) / 3f, 1f);
                star.preserveAspect = true;
            }
            return row;
        }

        // ---- RectTransform placement helpers (extension methods) ----

        /// <summary>Stretch over the whole parent, with optional margins in UI units.</summary>
        public static RectTransform Fill(this RectTransform rect, float left = 0f, float bottom = 0f, float right = 0f, float top = 0f)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(left, bottom);
            rect.offsetMax = new Vector2(-right, -top);
            return rect;
        }

        /// <summary>Cover a fraction of the parent: from (x0,y0) to (x1,y1), each 0..1.</summary>
        public static RectTransform Frac(this RectTransform rect, float x0, float y0, float x1, float y1)
        {
            rect.anchorMin = new Vector2(x0, y0);
            rect.anchorMax = new Vector2(x1, y1);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            return rect;
        }

        // ---- Direction-aware placement ----
        // Arabic reads right to left, so whole screens are mirrored: what
        // sits on the left in English sits on the right in Arabic. Use these
        // two for screen layout; use plain Frac / At for things that must
        // never flip (the mascot's face, a memory grid).

        /// <summary>True when the interface language is written right to left.</summary>
        public static bool RightToLeft
        {
            get { return Loc.Language == "ar"; }
        }

        /// <summary>Alignment for text that starts at the reading edge.</summary>
        public static TextAnchor StartAlign
        {
            get { return RightToLeft ? TextAnchor.MiddleRight : TextAnchor.MiddleLeft; }
        }

        /// <summary>Like Frac, but mirrored horizontally in right-to-left languages.</summary>
        public static RectTransform FracDir(this RectTransform rect, float x0, float y0, float x1, float y1)
        {
            return RightToLeft ? rect.Frac(1f - x1, y0, 1f - x0, y1) : rect.Frac(x0, y0, x1, y1);
        }

        /// <summary>Like At, but mirrored horizontally in right-to-left languages.</summary>
        public static RectTransform AtDir(this RectTransform rect, float anchorX, float anchorY, float width, float height)
        {
            return rect.At(RightToLeft ? 1f - anchorX : anchorX, anchorY, width, height);
        }

        /// <summary>A fixed size, centred on a point given as a fraction of the parent.</summary>
        public static RectTransform At(this RectTransform rect, float anchorX, float anchorY, float width, float height)
        {
            rect.anchorMin = rect.anchorMax = new Vector2(anchorX, anchorY);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(width, height);
            return rect;
        }
    }

    public class Card
    {
        public RectTransform Root;
        public RectTransform Face;
        public Image FaceImage;
        public Image Edge;

        public void SetColor(Color face)
        {
            FaceImage.color = face;
            Edge.color = Theme.Darker(face, 0.2f);
        }
    }

    /// <summary>
    /// Turns its object into a button. Unity calls these methods because the
    /// class implements the EventSystem pointer interfaces.
    /// </summary>
    public class PressButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerClickHandler
    {
        public Action OnTap;
        public bool Interactable = true;

        public void OnPointerDown(PointerEventData eventData)
        {
            if (Interactable) Tween.ScaleTo((RectTransform)transform, 0.93f, 0.08f);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (Interactable) Tween.ScaleTo((RectTransform)transform, 1f, 0.12f);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (Interactable && OnTap != null) OnTap();
        }
    }
}
