using UnityEngine;
using UnityEngine.UI;

namespace Nujoom
{
    /// <summary>
    /// Turns an ItemVisual from the content file into UI objects. This is the
    /// only place that knows how content becomes pictures, so adding a new
    /// "kind" means adding one case here.
    /// </summary>
    public static class Visuals
    {
        /// <summary>Fills the parent with a square drawing of the visual.</summary>
        public static RectTransform Build(Transform parent, ItemVisual visual, float padding = 0f)
        {
            RectTransform square = Ui.SquareIn("Visual", parent, padding);
            string value = visual.value.Of(Loc.Language);
            Color tint = string.IsNullOrEmpty(visual.color) ? Theme.Primary : Theme.Hex(visual.color);

            switch (visual.kind)
            {
                case "glyph":
                    Ui.Label("Glyph", square, value, 300, tint).rectTransform.Frac(0.08f, 0.02f, 0.92f, 0.98f);
                    break;

                case "label":
                    Ui.Label("Word", square, value, 64, Theme.Ink).rectTransform.Frac(0.04f, 0.2f, 0.96f, 0.8f);
                    break;

                case "color":
                    Ui.Img("Blob", square, Shapes.Blob, Theme.Hex(value)).rectTransform.Frac(0.08f, 0.08f, 0.92f, 0.92f);
                    Ui.Img("Shine", square, Shapes.Circle, new Color(1f, 1f, 1f, 0.45f)).rectTransform.Frac(0.3f, 0.6f, 0.44f, 0.74f);
                    break;

                case "shape":
                    Ui.Img("Shape", square, ShapeSprite(value), tint).rectTransform.Frac(0.1f, 0.1f, 0.9f, 0.9f);
                    break;

                case "dots":
                    int count;
                    if (!int.TryParse(value, out count)) count = 1;
                    BuildDots(square, Mathf.Clamp(count, 1, 9), tint);
                    break;

                case "sprite":
                    Image picture = Ui.Img("Picture", square, Shapes.Art(value), Color.white);
                    picture.rectTransform.Frac(0.04f, 0.04f, 0.96f, 0.96f);
                    picture.preserveAspect = true;
                    break;

                default:
                    Debug.LogWarning("Nujoom: unknown visual kind '" + visual.kind + "'");
                    break;
            }
            return square;
        }

        private static Sprite ShapeSprite(string shape)
        {
            switch (shape)
            {
                case "square": return Shapes.Rounded;
                case "triangle": return Shapes.Triangle;
                case "star": return Shapes.Star;
                case "heart": return Shapes.Heart;
                default: return Shapes.Circle;
            }
        }

        // Dot positions on a 3x3 grid (column, row), like the faces of a die.
        private static readonly int[][][] DotLayouts =
        {
            new[] { new[] { 1, 1 } },
            new[] { new[] { 0, 2 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 1, 1 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 2, 2 }, new[] { 0, 0 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 2, 2 }, new[] { 1, 1 }, new[] { 0, 0 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 2, 2 }, new[] { 0, 1 }, new[] { 2, 1 }, new[] { 0, 0 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 2, 2 }, new[] { 0, 1 }, new[] { 1, 1 }, new[] { 2, 1 }, new[] { 0, 0 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 1, 2 }, new[] { 2, 2 }, new[] { 0, 1 }, new[] { 2, 1 }, new[] { 0, 0 }, new[] { 1, 0 }, new[] { 2, 0 } },
            new[] { new[] { 0, 2 }, new[] { 1, 2 }, new[] { 2, 2 }, new[] { 0, 1 }, new[] { 1, 1 }, new[] { 2, 1 }, new[] { 0, 0 }, new[] { 1, 0 }, new[] { 2, 0 } },
        };

        private static void BuildDots(RectTransform square, int count, Color tint)
        {
            const float start = 0.14f, cell = 0.24f, size = 0.2f;
            foreach (int[] position in DotLayouts[count - 1])
            {
                float x = start + position[0] * cell + (cell - size) / 2f;
                float y = start + position[1] * cell + (cell - size) / 2f;
                Ui.Img("Dot", square, Shapes.Circle, tint).rectTransform.Frac(x, y, x + size, y + size);
            }
        }
    }

    /// <summary>
    /// A one-shot burst of confetti made of UI images moved every frame.
    /// (Exercise in the README: rebuild this with Unity's ParticleSystem.)
    /// </summary>
    public class Confetti : MonoBehaviour
    {
        private const int Pieces = 70;
        private const float Duration = 2.6f;

        private struct Piece
        {
            public RectTransform Rect;
            public Image Image;
            public float StartX, Drift, Speed, Delay, Spin, Wobble;
        }

        private static readonly Color[] Palette =
        {
            Theme.Hex("#FF5A5F"), Theme.Hex("#3D8BFF"), Theme.Hex("#2EC27E"),
            Theme.Hex("#FFC533"), Theme.Hex("#9B5DE5"), Theme.Hex("#FF7AB6"),
        };

        private Piece[] pieces;
        private float elapsed;
        private RectTransform area;

        /// <summary>Starts a burst that covers the given parent and removes itself when done.</summary>
        public static void Burst(Transform parent)
        {
            RectTransform root = Ui.Node("Confetti", parent).Fill();
            root.gameObject.AddComponent<Confetti>().area = root;
        }

        private void Start()
        {
            pieces = new Piece[Pieces];
            for (int i = 0; i < Pieces; i++)
            {
                bool round = Random.value > 0.5f;
                float size = Random.Range(12f, 24f);
                Image image = Ui.Img("Piece", area, round ? Shapes.Circle : null, Palette[Random.Range(0, Palette.Length)]);
                image.rectTransform.anchorMin = image.rectTransform.anchorMax = new Vector2(0f, 1f);
                image.rectTransform.sizeDelta = new Vector2(size, round ? size : size * 0.55f);
                pieces[i] = new Piece
                {
                    Rect = image.rectTransform,
                    Image = image,
                    StartX = Random.value,
                    Drift = Random.Range(-0.25f, 0.25f),
                    Speed = Random.Range(0.7f, 1.4f),
                    Delay = Random.Range(0f, 0.25f),
                    Spin = Random.Range(-400f, 400f),
                    Wobble = Random.Range(0f, Mathf.PI * 2f),
                };
            }
            Update(); // place the pieces above the screen before the first frame
        }

        private void Update()
        {
            if (pieces == null) return;
            elapsed += Time.deltaTime;
            float time = elapsed / Duration;
            if (time >= 1f)
            {
                Destroy(gameObject);
                return;
            }
            float width = area.rect.width, height = area.rect.height;
            foreach (Piece piece in pieces)
            {
                float t = Mathf.Clamp01((time - piece.Delay) / (1f - piece.Delay));
                float x = (piece.StartX + piece.Drift * t + Mathf.Sin(piece.Wobble + t * 9f) * 0.02f) * width;
                float y = 30f - t * piece.Speed * (height + 60f);
                piece.Rect.anchoredPosition = new Vector2(x, y);
                piece.Rect.localEulerAngles = new Vector3(0f, 0f, piece.Spin * t);
                piece.Image.color = Theme.WithAlpha(piece.Image.color, t > 0.8f ? (1f - t) / 0.2f : 1f);
            }
        }
    }
}
