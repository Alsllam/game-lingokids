using UnityEngine;
using UnityEngine.UI;

namespace Nujoom
{
    public enum MascotMood { Idle, Wave, Cheer, Sad, Talk }

    /// <summary>
    /// "Noor", the app's character, assembled from simple shapes and animated
    /// by moving, rotating and scaling those parts every frame in Update().
    ///
    /// This is what Unity's Animator does for you: an AnimationClip stores how
    /// each part's position / rotation / scale changes over time. Here the
    /// same curves are written as maths, so you can read exactly what happens.
    /// (Exercise in the README: replace this with an Animator Controller.)
    ///
    /// The rest of the app only ever calls Play(mood).
    /// </summary>
    public class Mascot : MonoBehaviour
    {
        private static readonly float[] Durations = { 0f, 1.4f, 1.1f, 1.0f, 1.3f };
        private const float LoopSeconds = 4f;
        private const float RestArm = 0.35f; // radians below horizontal

        private float size;
        private MascotMood mood = MascotMood.Idle;
        private float actionTime;
        private float loopTime;

        private RectTransform body, belly, shadow, leftArm, rightArm, star, antenna, group;
        private RectTransform leftEye, rightEye, leftPupil, rightPupil, smile, openMouth;
        private RectTransform leftFoot, rightFoot, leftCheek, rightCheek;

        /// <summary>Creates a mascot of the given size (UI units) inside parent.</summary>
        public static Mascot Create(Transform parent, float size)
        {
            RectTransform root = Ui.Node("Mascot", parent);
            root.sizeDelta = new Vector2(size, size);
            var mascot = root.gameObject.AddComponent<Mascot>();
            mascot.size = size;
            mascot.Build(root);
            return mascot;
        }

        /// <summary>Starts a one-shot animation; the mascot returns to idle by itself.</summary>
        public void Play(MascotMood newMood)
        {
            mood = newMood;
            actionTime = 0f;
        }

        // The hierarchy is drawn in creation order: first = at the back.
        private void Build(RectTransform root)
        {
            Color bodyColor = Theme.MascotBody;
            shadow = Part("Shadow", root, Shapes.Circle, Theme.WithAlpha(Theme.Ink, 0.12f));
            group = Ui.Node("Body Group", root);
            group.sizeDelta = Vector2.zero;

            leftFoot = Part("Left Foot", group, Shapes.Circle, Theme.Darker(bodyColor, 0.25f));
            rightFoot = Part("Right Foot", group, Shapes.Circle, Theme.Darker(bodyColor, 0.25f));
            leftArm = Part("Left Arm", group, Shapes.Rounded, Theme.Darker(bodyColor, 0.12f));
            rightArm = Part("Right Arm", group, Shapes.Rounded, Theme.Darker(bodyColor, 0.12f));
            // Arms rotate around the shoulder, so the pivot sits at one end.
            leftArm.pivot = rightArm.pivot = new Vector2(0f, 0.5f);
            antenna = Part("Antenna", group, Shapes.Rounded, Theme.Darker(bodyColor, 0.25f));
            antenna.pivot = new Vector2(0.5f, 0f);
            star = Part("Antenna Star", group, Shapes.Star, Theme.Star);

            body = Part("Body", group, Shapes.Circle, bodyColor);
            Part("Highlight", body, Shapes.Circle, Theme.WithAlpha(Color.white, 0.16f)).Frac(0.12f, 0.45f, 0.62f, 0.95f);
            belly = Part("Belly", group, Shapes.Circle, Theme.MascotBelly);

            leftEye = Part("Left Eye", group, Shapes.Circle, Color.white);
            rightEye = Part("Right Eye", group, Shapes.Circle, Color.white);
            leftPupil = Part("Left Pupil", group, Shapes.Circle, Theme.Ink);
            rightPupil = Part("Right Pupil", group, Shapes.Circle, Theme.Ink);
            leftCheek = Part("Left Cheek", group, Shapes.Circle, new Color(1f, 0.56f, 0.69f, 0.55f));
            rightCheek = Part("Right Cheek", group, Shapes.Circle, new Color(1f, 0.56f, 0.69f, 0.55f));
            smile = Part("Smile", group, Shapes.Smile, Theme.Ink);
            openMouth = Part("Open Mouth", group, Shapes.Circle, Theme.Ink);
            Part("Tongue", openMouth, Shapes.Circle, Theme.Hex("#FF6B8B")).Frac(0.2f, 0.05f, 0.8f, 0.5f);

            Pose();
        }

        private static RectTransform Part(string name, Transform parent, Sprite sprite, Color color)
        {
            return Ui.Img(name, parent, sprite, color).rectTransform;
        }

        private void Update()
        {
            loopTime = (loopTime + Time.deltaTime) % LoopSeconds;
            if (mood != MascotMood.Idle)
            {
                actionTime += Time.deltaTime;
                if (actionTime >= Durations[(int)mood]) mood = MascotMood.Idle;
            }
            Pose();
        }

        // Places a part. x and y are fractions of the mascot's size measured
        // from its centre (x right, y up); w and h are fractions too.
        private void Place(RectTransform part, float x, float y, float w, float h)
        {
            part.anchoredPosition = new Vector2(x * size, y * size);
            part.sizeDelta = new Vector2(w * size, h * size);
        }

        /// <summary>Computes the whole pose for this frame from two clocks.</summary>
        private void Pose()
        {
            float loop = loopTime / LoopSeconds;                       // 0..1, repeats forever
            float action = mood == MascotMood.Idle ? 0f : Mathf.Clamp01(actionTime / Durations[(int)mood]); // 0..1, once

            // Always running: breathing and blinking.
            float breathe = Mathf.Sin(loop * Mathf.PI * 4f) * 0.012f;
            float blinkPhase = (loop * 2f) % 1f;
            float blink = blinkPhase > 0.94f ? 1f - Mathf.Sin((blinkPhase - 0.94f) / 0.06f * Mathf.PI) : 1f;
            float starSpin = Mathf.Sin(loop * Mathf.PI * 2f) * 9f; // degrees

            float jump = 0f, sway = 0f, squash = 0f, mouthOpen = 0f, smileAmount = 1f, eyeDrop = 0f;
            float leftAngle = RestArm, rightAngle = RestArm;

            switch (mood)
            {
                case MascotMood.Wave:
                    float lift = Tween.OutQuad(Mathf.Clamp01(action * 4f));
                    float lower = Mathf.Pow(Mathf.Clamp01((action - 0.8f) * 5f), 2f);
                    float raised = lift * (1f - lower);
                    rightAngle = RestArm - raised * (1.25f + Mathf.Sin(action * Mathf.PI * 8f) * 0.35f);
                    mouthOpen = 0.35f * raised;
                    break;

                case MascotMood.Cheer:
                    float hop = Mathf.Abs(Mathf.Sin(action * Mathf.PI * 2f)); // two hops
                    jump = hop * 0.15f * (1f - action * 0.35f);
                    squash = -hop * 0.04f + (1f - hop) * 0.03f * (1f - action);
                    float up = Mathf.Clamp01(Mathf.Sin(action * Mathf.PI));
                    leftAngle = rightAngle = RestArm - up * 1.5f;
                    mouthOpen = up;
                    starSpin = action * 360f;
                    break;

                case MascotMood.Sad:
                    sway = Mathf.Sin(action * Mathf.PI * 5f) * 0.03f * (1f - action);
                    float down = Mathf.Clamp01(Mathf.Sin(action * Mathf.PI));
                    smileAmount = 1f - down * 1.8f; // below zero = frown
                    eyeDrop = down * 0.012f;
                    leftAngle = rightAngle = RestArm + down * 0.5f;
                    squash = down * 0.02f;
                    break;

                case MascotMood.Talk:
                    float envelope = Mathf.Clamp01(Mathf.Sin(action * Mathf.PI));
                    mouthOpen = Mathf.Abs(Mathf.Sin(action * Mathf.PI * 9f)) * 0.8f * envelope;
                    leftAngle = RestArm - envelope * 0.25f;
                    break;
            }

            // The shadow stays on the ground and shrinks while jumping.
            float shadowScale = 1f - jump * 2.2f;
            Place(shadow, 0f, -0.44f, 0.5f * shadowScale, 0.07f * shadowScale);

            // Everything else moves together with the jump and sway.
            group.anchoredPosition = new Vector2(sway * size, jump * size);

            float bodyY = -0.1f;
            float halfWidth = 0.29f + squash;
            float halfHeight = 0.30f - squash + breathe;
            Place(body, 0f, bodyY, halfWidth * 2f, halfHeight * 2f);
            Place(belly, 0f, bodyY - halfHeight * 0.38f, halfWidth * 1.15f, halfHeight * 0.95f);

            Place(leftFoot, -0.13f, -0.405f, 0.17f, 0.075f);
            Place(rightFoot, 0.13f, -0.405f, 0.17f, 0.075f);

            // Arms: a rounded bar rotated around the shoulder.
            float shoulderY = bodyY + halfHeight * 0.05f;
            Place(rightArm, halfWidth * 0.88f, shoulderY, 0.2f, 0.075f);
            rightArm.localEulerAngles = new Vector3(0f, 0f, -rightAngle * Mathf.Rad2Deg);
            Place(leftArm, -halfWidth * 0.88f, shoulderY, 0.2f, 0.075f);
            leftArm.localEulerAngles = new Vector3(0f, 0f, 180f + leftAngle * Mathf.Rad2Deg);

            float headTop = bodyY + halfHeight;
            Place(antenna, 0f, headTop - 0.02f, 0.024f, 0.14f);
            Place(star, 0.005f, headTop + 0.13f, 0.15f, 0.15f);
            star.localEulerAngles = new Vector3(0f, 0f, -starSpin);

            float eyeY = bodyY + halfHeight * 0.22f - eyeDrop;
            float eyeX = halfWidth * 0.42f;
            const float eyeSize = 0.124f;
            float lid = Mathf.Clamp(blink, 0.08f, 1f);
            Place(leftEye, -eyeX, eyeY, eyeSize, eyeSize * lid);
            Place(rightEye, eyeX, eyeY, eyeSize, eyeSize * lid);
            bool eyesOpen = blink > 0.4f;
            leftPupil.gameObject.SetActive(eyesOpen);
            rightPupil.gameObject.SetActive(eyesOpen);
            Place(leftPupil, -eyeX, eyeY - 0.006f - eyeDrop, eyeSize * 0.52f, eyeSize * 0.52f);
            Place(rightPupil, eyeX, eyeY - 0.006f - eyeDrop, eyeSize * 0.52f, eyeSize * 0.52f);

            Place(leftCheek, -halfWidth * 0.68f, bodyY - halfHeight * 0.02f, 0.075f, 0.05f);
            Place(rightCheek, halfWidth * 0.68f, bodyY - halfHeight * 0.02f, 0.075f, 0.05f);

            // Mouth: a curved line when closed, an oval when open.
            float mouthY = bodyY - halfHeight * 0.06f;
            bool open = mouthOpen > 0.12f;
            smile.gameObject.SetActive(!open);
            openMouth.gameObject.SetActive(open);
            if (open)
            {
                Place(openMouth, 0f, mouthY - 0.012f, 0.13f, 0.035f + 0.075f * mouthOpen);
            }
            else
            {
                // The sprite is a smile; a negative height flips it into a frown.
                Place(smile, 0f, mouthY - 0.02f * smileAmount, 0.2f, 0.09f);
                smile.localScale = new Vector3(1f, Mathf.Clamp(smileAmount, -1f, 1f), 1f);
            }
        }
    }
}
