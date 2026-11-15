using System;
using System.Collections;
using UnityEngine;

namespace Nujoom
{
    /// <summary>
    /// A very small tween library built on coroutines.
    ///
    /// "Tweening" = changing a value smoothly over time (a size, a position).
    /// Real projects usually use DOTween from the Asset Store; this file shows
    /// what such a library does inside, in about a hundred lines.
    ///
    /// Every tween runs on the object it animates, so destroying the object
    /// stops its tweens automatically.
    /// </summary>
    public static class Tween
    {
        // ---- Easing curves: how progress (0..1) is bent to feel natural ----

        public static float Linear(float t) { return t; }

        public static float OutQuad(float t) { return 1f - (1f - t) * (1f - t); }

        public static float InOutQuad(float t)
        {
            return t < 0.5f ? 2f * t * t : 1f - Mathf.Pow(-2f * t + 2f, 2f) / 2f;
        }

        /// <summary>Overshoots a little, then settles: a friendly "pop".</summary>
        public static float OutBack(float t)
        {
            const float c1 = 1.70158f, c3 = c1 + 1f;
            return 1f + c3 * Mathf.Pow(t - 1f, 3f) + c1 * Mathf.Pow(t - 1f, 2f);
        }

        /// <summary>Springs past the end and wobbles back.</summary>
        public static float OutElastic(float t)
        {
            if (t <= 0f) return 0f;
            if (t >= 1f) return 1f;
            const float c4 = 2f * Mathf.PI / 3f;
            return Mathf.Pow(2f, -10f * t) * Mathf.Sin((t * 10f - 0.75f) * c4) + 1f;
        }

        // ---- The engine ----

        /// <summary>
        /// Calls step(value) every frame for "duration" seconds, where value
        /// goes from 0 to 1 through the easing curve. Then calls done.
        /// </summary>
        public static void Run(GameObject host, float duration, Action<float> step,
            Func<float, float> ease = null, float delay = 0f, Action done = null)
        {
            if (host == null || !host.activeInHierarchy) return;
            TweenHost runner = host.GetComponent<TweenHost>();
            if (runner == null) runner = host.AddComponent<TweenHost>();
            runner.StartCoroutine(Routine(duration, step, ease ?? OutQuad, delay, done));
        }

        private static IEnumerator Routine(float duration, Action<float> step, Func<float, float> ease, float delay, Action done)
        {
            if (delay > 0f) yield return new WaitForSeconds(delay);
            float elapsed = 0f;
            while (elapsed < duration)
            {
                if (step != null) step(ease(Mathf.Clamp01(elapsed / duration)));
                elapsed += Time.deltaTime;
                yield return null; // wait one frame
            }
            if (step != null) step(ease(1f));
            if (done != null) done();
        }

        /// <summary>Runs an action after a pause.</summary>
        public static void Delay(GameObject host, float seconds, Action action)
        {
            Run(host, 0f, null, null, seconds, action);
        }

        // ---- Ready-made effects ----

        /// <summary>Grows from nothing with a bouncy overshoot.</summary>
        public static void PopIn(RectTransform target, float delay = 0f, float duration = 0.45f)
        {
            target.localScale = Vector3.zero;
            Run(target.gameObject, duration, t => target.localScale = Vector3.one * t, OutBack, delay);
        }

        /// <summary>A quick "boing": bigger, then back to normal.</summary>
        public static void Punch(RectTransform target, float amount = 0.18f, float duration = 0.4f)
        {
            Run(target.gameObject, duration, t => target.localScale = Vector3.one * (1f + amount * (1f - t)), OutElastic,
                0f, () => target.localScale = Vector3.one);
        }

        /// <summary>Shakes sideways to say "not this one".</summary>
        public static void Shake(RectTransform target, float strength = 14f, float duration = 0.42f)
        {
            TweenHost runner = target.GetComponent<TweenHost>();
            if (runner != null && runner.Shaking) return; // do not stack shakes
            Vector2 home = target.anchoredPosition;
            Run(target.gameObject, duration, t =>
            {
                float offset = Mathf.Sin(t * Mathf.PI * 6f) * strength * (1f - t);
                target.anchoredPosition = home + new Vector2(offset, 0f);
            }, Linear, 0f, () =>
            {
                target.anchoredPosition = home;
                TweenHost host = target.GetComponent<TweenHost>();
                if (host != null) host.Shaking = false;
            });
            runner = target.GetComponent<TweenHost>();
            if (runner != null) runner.Shaking = true;
        }

        /// <summary>Slides to a position.</summary>
        public static void MoveTo(RectTransform target, Vector2 destination, float duration = 0.25f, Action done = null)
        {
            Vector2 start = target.anchoredPosition;
            Run(target.gameObject, duration, t => target.anchoredPosition = Vector2.LerpUnclamped(start, destination, t), OutQuad, 0f, done);
        }

        public static void ScaleTo(RectTransform target, float scale, float duration = 0.2f)
        {
            Vector3 start = target.localScale;
            Run(target.gameObject, duration, t => target.localScale = Vector3.LerpUnclamped(start, Vector3.one * scale, t));
        }

        public static void FadeTo(CanvasGroup group, float alpha, float duration = 0.3f)
        {
            float start = group.alpha;
            Run(group.gameObject, duration, t => group.alpha = Mathf.Lerp(start, alpha, t));
        }

        /// <summary>
        /// A card flip: squeeze to a thin line, call atHalf (swap what the
        /// card shows), then open again.
        /// </summary>
        public static void Flip(RectTransform target, Action atHalf, float duration = 0.3f)
        {
            Run(target.gameObject, duration / 2f, t => target.localScale = new Vector3(1f - t, 1f, 1f), InOutQuad, 0f, () =>
            {
                if (atHalf != null) atHalf();
                Run(target.gameObject, duration / 2f, t => target.localScale = new Vector3(t, 1f, 1f), InOutQuad);
            });
        }
    }

    /// <summary>An empty component whose only job is to run tween coroutines.</summary>
    public class TweenHost : MonoBehaviour
    {
        [NonSerialized] public bool Shaking;
    }
}
