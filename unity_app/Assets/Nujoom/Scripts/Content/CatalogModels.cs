using System;
using System.Collections.Generic;

namespace Nujoom
{
    // The content model. These classes mirror catalog.json field by field so
    // Unity's JsonUtility can fill them directly. They contain no UnityEngine
    // types, which keeps the game rules testable outside Unity.

    [Serializable]
    public class LocalizedText
    {
        public string ar = "";
        public string en = "";

        public string Of(string language)
        {
            return language == "ar" ? ar : en;
        }
    }

    /// <summary>
    /// What to draw for an item. kind is one of:
    ///   glyph  - a big letter or digit (value = the character)
    ///   color  - a paint blob (value = hex colour)
    ///   shape  - circle | square | triangle | star | heart
    ///   dots   - counting dots (value = how many)
    ///   sprite - a picture from Resources/Art (value = file name)
    ///   label  - a written word
    /// </summary>
    [Serializable]
    public class ItemVisual
    {
        public string kind = "";
        public LocalizedText value = new LocalizedText();
        public string color = "";

        public bool IsEmpty
        {
            get { return string.IsNullOrEmpty(kind); }
        }
    }

    [Serializable]
    public class LearningItem
    {
        public string id = "";
        public LocalizedText name = new LocalizedText();
        public ItemVisual visual = new ItemVisual();

        /// <summary>Optional partner for the matching game (digit -> dots).</summary>
        public ItemVisual pair = new ItemVisual();

        /// <summary>The pair, or the written name when no pair is given.</summary>
        public ItemVisual PairOrLabel
        {
            get
            {
                if (pair != null && !pair.IsEmpty) return pair;
                return new ItemVisual { kind = "label", value = name };
            }
        }
    }

    [Serializable]
    public class Activity
    {
        public string id = "";

        /// <summary>The game template: choice | memory | match.</summary>
        public string type = "";
        public int rounds;
    }

    [Serializable]
    public class Topic
    {
        public string id = "";
        public LocalizedText title = new LocalizedText();
        public string color = "";
        public ItemVisual icon = new ItemVisual();
        public List<LearningItem> items = new List<LearningItem>();
        public List<Activity> activities = new List<Activity>();
    }

    [Serializable]
    public class Catalog
    {
        public int version;
        public List<Topic> topics = new List<Topic>();

        public Topic FindTopic(string topicId)
        {
            foreach (Topic topic in topics)
            {
                if (topic.id == topicId) return topic;
            }
            return null;
        }

        /// <summary>
        /// Checks the content and returns a list of human-readable problems
        /// (empty when everything is fine). Run on load so a typo in the JSON
        /// is reported clearly instead of breaking a game later.
        /// </summary>
        public List<string> Validate()
        {
            var problems = new List<string>();
            var knownTypes = new HashSet<string> { "choice", "memory", "match" };
            var activityIds = new HashSet<string>();
            if (topics.Count == 0) problems.Add("catalog has no topics");
            foreach (Topic topic in topics)
            {
                if (string.IsNullOrEmpty(topic.id)) problems.Add("a topic has no id");
                if (topic.items.Count < 2) problems.Add(topic.id + ": needs at least 2 items");
                var itemIds = new HashSet<string>();
                foreach (LearningItem item in topic.items)
                {
                    if (!itemIds.Add(item.id)) problems.Add(topic.id + ": duplicate item id '" + item.id + "'");
                    if (item.visual == null || item.visual.IsEmpty) problems.Add(topic.id + "." + item.id + ": missing visual");
                    if (string.IsNullOrEmpty(item.name.ar) || string.IsNullOrEmpty(item.name.en))
                        problems.Add(topic.id + "." + item.id + ": name needs both ar and en");
                }
                foreach (Activity activity in topic.activities)
                {
                    if (!activityIds.Add(activity.id)) problems.Add("duplicate activity id '" + activity.id + "'");
                    if (!knownTypes.Contains(activity.type))
                        problems.Add(activity.id + ": unknown game type '" + activity.type + "'");
                }
            }
            return problems;
        }
    }
}
