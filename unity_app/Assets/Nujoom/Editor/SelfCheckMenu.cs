using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Nujoom
{
    /// <summary>
    /// Adds the menu  Nujoom > Run Self Check  to the Unity Editor.
    /// Scripts inside a folder named "Editor" only exist in the Editor and
    /// are never included in the built game.
    /// </summary>
    public static class SelfCheckMenu
    {
        [MenuItem("Nujoom/Run Self Check")]
        public static void Run()
        {
            Catalog catalog = CatalogLoader.Load();
            int checks;
            List<string> failures = SelfCheck.RunAll(catalog, out checks);
            foreach (string failure in failures) Debug.LogError("Nujoom self check FAILED: " + failure);
            if (failures.Count == 0) Debug.Log("Nujoom self check: all " + checks + " checks passed.");
            if (catalog == null) Debug.LogError("Nujoom self check: the catalog could not be loaded (see errors above).");
        }

        [MenuItem("Nujoom/Clear Saved Progress")]
        public static void ClearProgress()
        {
            PlayerPrefs.DeleteAll();
            Debug.Log("Nujoom: saved settings and stars were cleared.");
        }
    }
}
