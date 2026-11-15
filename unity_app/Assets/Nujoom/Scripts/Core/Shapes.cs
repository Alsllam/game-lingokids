using System;
using System.Collections.Generic;
using UnityEngine;

namespace Nujoom
{
    /// <summary>The app's colours in one place.</summary>
    public static class Theme
    {
        public static readonly Color SkyTop = Hex("#8FD8FF");
        public static readonly Color SkyBottom = Hex("#E6F8FF");
        public static readonly Color Ground = Hex("#8BD67A");
        public static readonly Color Card = Color.white;
        public static readonly Color Ink = Hex("#1F2A44");
        public static readonly Color InkSoft = Hex("#5B6785");
        public static readonly Color Primary = Hex("#3D8BFF");
        public static readonly Color Success = Hex("#2EC27E");
        public static readonly Color Danger = Hex("#FF5A5F");
        public static readonly Color Star = Hex("#FFC533");
        public static readonly Color StarEmpty = Hex("#D9DFEC");
        public static readonly Color MascotBody = Hex("#7C5CFF");
        public static readonly Color MascotBelly = Hex("#EDE7FF");

        /// <summary>Parses "#RRGGBB" or "#AARRGGBB". Returns magenta on bad input so mistakes are visible.</summary>
        public static Color Hex(string hex)
        {
            if (string.IsNullOrEmpty(hex)) return Color.magenta;
            string digits = hex.TrimStart('#');
            uint value;
            if (!uint.TryParse(digits, System.Globalization.NumberStyles.HexNumber, null, out value)) return Color.magenta;
            if (digits.Length == 6) value |= 0xFF000000;
            else if (digits.Length != 8) return Color.magenta;
            byte a = (byte)(value >> 24), r = (byte)(value >> 16), g = (byte)(value >> 8), b = (byte)value;
            return new Color32(r, g, b, a);
        }

        public static Color Darker(Color color, float amount)
        {
            return Color.Lerp(color, Ink, amount);
        }

        public static Color Lighter(Color color, float amount)
        {
            return Color.Lerp(color, Color.white, amount);
        }

        public static Color WithAlpha(Color color, float alpha)
        {
            color.a = alpha;
            return color;
        }
    }

    /// <summary>
    /// Builds simple white sprites in code (circle, rounded card, star, heart...).
    /// A UI Image then tints them with any colour.
    ///
    /// Why: this project starts with zero art files so it runs immediately.
    /// In a normal Unity project these would be PNG sprites made by an artist
    /// and assigned in the Inspector - see the exercises in the README.
    /// </summary>
    public static class Shapes
    {
        private static readonly Dictionary<string, Sprite> Cache = new Dictionary<string, Sprite>();

        public static Sprite Circle
        {
            get { return Get("circle", 128, 128, (x, y) => x * x + y * y <= 1f); }
        }

        /// <summary>A rounded square that stretches without distorting its corners (9-slice).</summary>
        public static Sprite Rounded
        {
            get
            {
                const float corner = 0.6f; // corner radius as a fraction of half the texture
                return Get("rounded", 64, 64, (x, y) =>
                {
                    float dx = Mathf.Max(Mathf.Abs(x) - (1f - corner), 0f);
                    float dy = Mathf.Max(Mathf.Abs(y) - (1f - corner), 0f);
                    return dx * dx + dy * dy <= corner * corner;
                }, new Vector4(24, 24, 24, 24));
            }
        }

        public static Sprite Star
        {
            get
            {
                var points = new Vector2[10];
                for (int i = 0; i < 10; i++)
                {
                    float radius = i % 2 == 0 ? 0.97f : 0.48f;
                    float angle = Mathf.PI / 2f + i * Mathf.PI / 5f;
                    points[i] = new Vector2(Mathf.Cos(angle) * radius, Mathf.Sin(angle) * radius);
                }
                return Get("star", 192, 192, (x, y) => InsidePolygon(points, x, y));
            }
        }

        public static Sprite Triangle
        {
            get
            {
                var points = new[] { new Vector2(0f, 0.92f), new Vector2(0.96f, -0.8f), new Vector2(-0.96f, -0.8f) };
                return Get("triangle", 192, 192, (x, y) => InsidePolygon(points, x, y));
            }
        }

        public static Sprite Heart
        {
            get
            {
                // The classic heart curve: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
                return Get("heart", 192, 192, (x, y) =>
                {
                    float hx = x * 1.22f;
                    float hy = y * 1.22f + 0.12f;
                    float k = hx * hx + hy * hy - 1f;
                    return k * k * k - hx * hx * hy * hy * hy <= 0f;
                });
            }
        }

        /// <summary>A wobbly paint blob for the colours topic.</summary>
        public static Sprite Blob
        {
            get
            {
                return Get("blob", 192, 192, (x, y) =>
                {
                    float limit = 0.88f * (1f + 0.07f * Mathf.Sin(Mathf.Atan2(y, x) * 7f));
                    return x * x + y * y <= limit * limit;
                });
            }
        }

        /// <summary>A curved line: a smile. Flip it vertically for a frown.</summary>
        public static Sprite Smile
        {
            get
            {
                return Get("smile", 128, 64, (x, y) =>
                {
                    if (Mathf.Abs(x) > 0.92f) return false;
                    float curve = 0.55f - 1.1f * (1f - x * x); // ends up, middle down
                    return Mathf.Abs(y - curve) < 0.3f;
                });
            }
        }

        /// <summary>
        /// Rasterises a shape. "inside" receives coordinates from -1 to 1
        /// (x to the right, y up). Each pixel is sampled 4x4 times so edges
        /// come out smooth.
        /// </summary>
        private static Sprite Get(string key, int width, int height, Func<float, float, bool> inside, Vector4 border = default(Vector4))
        {
            Sprite cached;
            if (Cache.TryGetValue(key, out cached) && cached != null) return cached;

            const int samples = 4;
            var pixels = new Color32[width * height];
            for (int py = 0; py < height; py++)
            {
                for (int px = 0; px < width; px++)
                {
                    int hits = 0;
                    for (int sy = 0; sy < samples; sy++)
                    {
                        for (int sx = 0; sx < samples; sx++)
                        {
                            float x = ((px + (sx + 0.5f) / samples) / width) * 2f - 1f;
                            float y = ((py + (sy + 0.5f) / samples) / height) * 2f - 1f;
                            if (inside(x, y)) hits++;
                        }
                    }
                    byte alpha = (byte)(255 * hits / (samples * samples));
                    pixels[py * width + px] = new Color32(255, 255, 255, alpha);
                }
            }

            var texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            texture.name = "Generated " + key;
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.filterMode = FilterMode.Bilinear;
            texture.SetPixels32(pixels);
            texture.Apply();

            Sprite sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, border);
            sprite.name = key;
            Cache[key] = sprite;
            return sprite;
        }

        // Even-odd rule: count how many polygon edges a ray to the right crosses.
        private static bool InsidePolygon(Vector2[] points, float x, float y)
        {
            bool inside = false;
            for (int i = 0, j = points.Length - 1; i < points.Length; j = i++)
            {
                Vector2 a = points[i], b = points[j];
                if ((a.y > y) != (b.y > y) && x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) inside = !inside;
            }
            return inside;
        }

        /// <summary>Loads a picture from Resources/Art and wraps it in a Sprite.</summary>
        public static Sprite Art(string name)
        {
            string key = "art:" + name;
            Sprite cached;
            if (Cache.TryGetValue(key, out cached) && cached != null) return cached;
            // Loading as Texture2D works whatever the import settings are
            // (2D projects import PNGs as Sprite, 3D projects as Default).
            var texture = Resources.Load<Texture2D>("Art/" + name);
            if (texture == null)
            {
                Debug.LogWarning("Nujoom: picture not found: Resources/Art/" + name);
                return null;
            }
            Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
            Cache[key] = sprite;
            return sprite;
        }
    }
}
