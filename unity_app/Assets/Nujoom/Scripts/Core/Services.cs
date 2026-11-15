using System.Collections.Generic;
using UnityEngine;

namespace Nujoom
{
    /// <summary>Interface strings in both languages. Content text lives in catalog.json.</summary>
    public static class Loc
    {
        /// <summary>"ar" or "en".</summary>
        public static string Language = "ar";

        // key -> { English, Arabic }
        private static readonly Dictionary<string, string[]> Strings = new Dictionary<string, string[]>
        {
            { "appTitle", new[] { "Nujoom", "نجوم" } },
            { "greeting", new[] { "Hi! Let's play!", "مرحبا! هيا نلعب!" } },
            { "gameChoice", new[] { "Find it", "أين هو؟" } },
            { "gameMemory", new[] { "Memory", "الذاكرة" } },
            { "gameMatch", new[] { "Match", "التوصيل" } },
            { "findPrompt", new[] { "Where is: {0}?", "أين: {0}؟" } },
            { "memoryPrompt", new[] { "Find the matching pairs", "ابحث عن الأزواج المتشابهة" } },
            { "matchPrompt", new[] { "Drag each one to its place", "اسحب كل واحد إلى مكانه" } },
            { "resultGreat", new[] { "Amazing!", "رائع جدا!" } },
            { "resultGood", new[] { "Well done!", "أحسنت!" } },
            { "resultTry", new[] { "Good try!", "محاولة جيدة!" } },
            { "playAgain", new[] { "Play again", "العب مرة أخرى" } },
            { "done", new[] { "Done", "تم" } },
            { "parents", new[] { "Parents", "الأهل" } },
            { "gateTitle", new[] { "For grown-ups only", "للكبار فقط" } },
            { "gateQuestion", new[] { "How much is {0} × {1}?", "كم يساوي {0} × {1}؟" } },
            { "gateWrong", new[] { "Not quite. Try again.", "إجابة غير صحيحة. حاول مرة أخرى." } },
            { "language", new[] { "Language", "اللغة" } },
            { "sound", new[] { "Sound effects", "المؤثرات الصوتية" } },
            { "on", new[] { "On", "تعمل" } },
            { "off", new[] { "Off", "متوقفة" } },
            { "reset", new[] { "Reset progress", "تصفير التقدم" } },
            { "resetConfirm", new[] { "Tap again to confirm", "اضغط مرة أخرى للتأكيد" } },
            { "resetDone", new[] { "Progress was reset", "تم تصفير التقدم" } },
            { "loadError", new[] { "Could not load the content.", "تعذر تحميل المحتوى." } },
        };

        public static string Get(string key)
        {
            string[] pair;
            if (!Strings.TryGetValue(key, out pair)) return key; // a visible hint that a key is missing
            return Language == "ar" ? pair[1] : pair[0];
        }

        public static string Format(string key, params object[] args)
        {
            return string.Format(Get(key), args);
        }
    }

    /// <summary>
    /// Saved data. PlayerPrefs is Unity's simple key-value storage; it is fine
    /// for small, non-sensitive things like settings and stars.
    /// </summary>
    public static class Store
    {
        public static string Language
        {
            get { return PlayerPrefs.GetString("settings.language", "ar") == "en" ? "en" : "ar"; }
            set { PlayerPrefs.SetString("settings.language", value); PlayerPrefs.Save(); }
        }

        public static bool SoundOn
        {
            get { return PlayerPrefs.GetInt("settings.sound", 1) == 1; }
            set { PlayerPrefs.SetInt("settings.sound", value ? 1 : 0); PlayerPrefs.Save(); }
        }

        public static int StarsFor(string activityId)
        {
            return Mathf.Clamp(PlayerPrefs.GetInt("stars." + activityId, 0), 0, 3);
        }

        /// <summary>Keeps the best result for an activity.</summary>
        public static void SaveBest(string activityId, int stars)
        {
            stars = Mathf.Clamp(stars, 1, 3);
            if (stars <= StarsFor(activityId)) return;
            PlayerPrefs.SetInt("stars." + activityId, stars);
            PlayerPrefs.Save();
        }

        public static int StarsIn(Topic topic)
        {
            int total = 0;
            foreach (Activity activity in topic.activities) total += StarsFor(activity.id);
            return total;
        }

        public static int TotalStars(Catalog catalog)
        {
            int total = 0;
            foreach (Topic topic in catalog.topics) total += StarsIn(topic);
            return total;
        }

        public static void ResetProgress(Catalog catalog)
        {
            foreach (Topic topic in catalog.topics)
            {
                foreach (Activity activity in topic.activities) PlayerPrefs.DeleteKey("stars." + activity.id);
            }
            PlayerPrefs.Save();
        }
    }

    /// <summary>Plays the short sound effects found in Resources/Audio.</summary>
    public class Sfx : MonoBehaviour
    {
        public const string Tap = "tap", Flip = "flip", Correct = "correct", Wrong = "wrong", Star = "star", Win = "win";

        private AudioSource source;
        private readonly Dictionary<string, AudioClip> clips = new Dictionary<string, AudioClip>();

        private void Awake()
        {
            source = gameObject.AddComponent<AudioSource>();
            source.playOnAwake = false;
        }

        public void Play(string clipName)
        {
            if (!Store.SoundOn) return;
            AudioClip clip;
            if (!clips.TryGetValue(clipName, out clip))
            {
                clip = Resources.Load<AudioClip>("Audio/" + clipName);
                clips[clipName] = clip;
                if (clip == null) Debug.LogWarning("Nujoom: sound not found: Resources/Audio/" + clipName);
            }
            // PlayOneShot lets several effects overlap on one AudioSource.
            if (clip != null) source.PlayOneShot(clip);
        }
    }

    /// <summary>Reads and checks catalog.json.</summary>
    public static class CatalogLoader
    {
        /// <summary>Returns null (and logs why) when the content cannot be used.</summary>
        public static Catalog Load()
        {
            var asset = Resources.Load<TextAsset>("catalog");
            if (asset == null)
            {
                Debug.LogError("Nujoom: Resources/catalog.json is missing.");
                return null;
            }
            Catalog catalog;
            try
            {
                catalog = JsonUtility.FromJson<Catalog>(asset.text);
            }
            catch (System.Exception error)
            {
                Debug.LogError("Nujoom: catalog.json is not valid JSON: " + error.Message);
                return null;
            }
            if (catalog == null) return null;
            List<string> problems = catalog.Validate();
            foreach (string problem in problems) Debug.LogError("Nujoom content problem: " + problem);
            return problems.Count == 0 ? catalog : null;
        }
    }
}
