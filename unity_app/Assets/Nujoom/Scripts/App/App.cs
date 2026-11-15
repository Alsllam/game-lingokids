using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Nujoom
{
    /// <summary>
    /// The entry point. Unity calls Boot() by itself after the first scene
    /// loads, so the project runs from ANY scene (even an empty one) with no
    /// manual setup: no objects to place, nothing to drag in the Inspector.
    ///
    /// Boot creates one object that carries the app, the Canvas (the root of
    /// all UI) and the EventSystem (which turns touches into UI events).
    /// </summary>
    public class App : MonoBehaviour
    {
        /// <summary>The single App instance, reachable from anywhere.</summary>
        public static App I { get; private set; }

        public Catalog Catalog { get; private set; }
        public Sfx Sfx { get; private set; }
        public Canvas Canvas { get; private set; }

        private RectTransform canvasRoot;
        private GameObject currentScreen;
        private Sprite skySprite;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            if (I != null) return;
            var go = new GameObject("Nujoom App");
            DontDestroyOnLoad(go);
            go.AddComponent<App>();
        }

        private void Awake()
        {
            I = this;
            Application.targetFrameRate = 60;

            // Landscape only.
            Screen.autorotateToPortrait = false;
            Screen.autorotateToPortraitUpsideDown = false;
            Screen.autorotateToLandscapeLeft = true;
            Screen.autorotateToLandscapeRight = true;
            Screen.orientation = ScreenOrientation.AutoRotation;

            Ui.Font = Resources.Load<Font>("Fonts/NotoKufiArabic");
            if (Ui.Font == null)
            {
                Debug.LogWarning("Nujoom: font not found in Resources/Fonts; using a system font (Arabic may not join).");
                Ui.Font = Font.CreateDynamicFontFromOSFont("Arial", 32);
            }

            Loc.Language = Store.Language;
            Sfx = gameObject.AddComponent<Sfx>();
            Catalog = CatalogLoader.Load();
            BuildCanvas();

#if UNITY_EDITOR
            RunSelfCheck();
#endif
            HomeScreen.Show();
        }

        private void BuildCanvas()
        {
            var canvasObject = new GameObject("Canvas", typeof(RectTransform));
            canvasObject.transform.SetParent(transform, false);
            Canvas = canvasObject.AddComponent<Canvas>();
            Canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            // The UI is designed for 1280x720 and scaled to any screen. With
            // "Expand", wider or taller screens get extra room instead of
            // cropping, which is why layouts use fractions of the parent.
            var scaler = canvasObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280f, 720f);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.Expand;

            canvasObject.AddComponent<GraphicRaycaster>();
            canvasRoot = (RectTransform)canvasObject.transform;

            if (EventSystem.current == null)
            {
                var eventObject = new GameObject("EventSystem", typeof(EventSystem));
                eventObject.transform.SetParent(transform, false);
                // Projects using Unity's newer Input System need its own UI
                // module; older projects use StandaloneInputModule. Looking
                // the type up by name supports both without a compile error.
                Type inputSystemModule = Type.GetType("UnityEngine.InputSystem.UI.InputSystemUIInputModule, Unity.InputSystem");
                if (inputSystemModule != null) eventObject.AddComponent(inputSystemModule);
                else eventObject.AddComponent<StandaloneInputModule>();
            }

            if (Camera.main != null) Camera.main.backgroundColor = Theme.SkyBottom;
        }

        /// <summary>
        /// Removes the current screen and returns the root of a new, empty one
        /// with the shared sky-and-grass background.
        /// </summary>
        public RectTransform NewScreen(string screenName)
        {
            if (currentScreen != null) Destroy(currentScreen);
            RectTransform root = Ui.Node(screenName, canvasRoot).Fill();
            currentScreen = root.gameObject;

            Ui.Img("Sky", root, SkySprite(), Color.white).rectTransform.Fill();
            Ui.Img("Hill", root, Shapes.Circle, Theme.Ground).rectTransform.Frac(-0.25f, -0.2f, 1.25f, 0.14f);
            return root;
        }

        public void SetLanguage(string language)
        {
            Store.Language = language;
            Loc.Language = Store.Language;
        }

        // A 1x64 texture fading from the bottom sky colour to the top one.
        private Sprite SkySprite()
        {
            if (skySprite != null) return skySprite;
            const int height = 64;
            var texture = new Texture2D(1, height, TextureFormat.RGBA32, false);
            texture.wrapMode = TextureWrapMode.Clamp;
            var pixels = new Color32[height];
            for (int y = 0; y < height; y++)
            {
                pixels[y] = Color.Lerp(Theme.SkyBottom, Theme.SkyTop, y / (height - 1f));
            }
            texture.SetPixels32(pixels);
            texture.Apply();
            skySprite = Sprite.Create(texture, new Rect(0, 0, 1, height), new Vector2(0.5f, 0.5f), 100f);
            return skySprite;
        }

        private void RunSelfCheck()
        {
            int checks;
            List<string> failures = SelfCheck.RunAll(Catalog, out checks);
            if (failures.Count == 0)
            {
                Debug.Log("Nujoom self check: all " + checks + " checks passed.");
                return;
            }
            foreach (string failure in failures) Debug.LogError("Nujoom self check FAILED: " + failure);
        }
    }
}
