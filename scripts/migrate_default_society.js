/**
 * એક વખત ચલાવો: બધા હાલના ડૉક્યુમેન્ટ પર societyId = "default" ઉમેરે.
 *
 * ચલાવો (કોઈ પણ એક):
 *   પ્રોજેક્ટ રૂટ:  node scripts/migrate_default_society.js
 *   functions ફોલ્ડર:  node ../scripts/migrate_default_society.js
 *
 * firebase-admin `functions/node_modules` માંથી લોડ થાય છે.
 */
const path = require("path");
const fs = require("fs");

const functionsAdmin = path.join(__dirname, "..", "functions", "node_modules", "firebase-admin");
if (!fs.existsSync(functionsAdmin)) {
  console.error(
    "firebase-admin મળ્યું નથી. પહેલા ચલાવો:  cd functions  &&  npm install",
  );
  process.exit(1);
}
const admin = require(functionsAdmin);

const DEFAULT = "default";

function resolveProjectId() {
  if (process.env.GCLOUD_PROJECT) return process.env.GCLOUD_PROJECT;
  if (process.env.GOOGLE_CLOUD_PROJECT) return process.env.GOOGLE_CLOUD_PROJECT;
  const rcPath = path.join(__dirname, "..", ".firebaserc");
  if (fs.existsSync(rcPath)) {
    try {
      const rc = JSON.parse(fs.readFileSync(rcPath, "utf8"));
      const id = rc.projects && rc.projects.default;
      if (id && String(id).trim()) return String(id).trim();
    } catch (_) {
      /* ignore */
    }
  }
  return null;
}

const projectId = resolveProjectId();
if (!projectId) {
  console.error(
    "Project Id મળ્યો નથી. .firebaserc માં projects.default ઉમેરો અથવા:\n" +
      "  $env:GCLOUD_PROJECT=\"your-project-id\"",
  );
  process.exit(1);
}

admin.initializeApp({ projectId });
const db = admin.firestore();

async function mergeSocietyId(collectionId) {
  const snap = await db.collection(collectionId).get();
  let updated = 0;
  let batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.societyId != null && String(data.societyId).trim() !== "") {
      continue;
    }
    batch.set(doc.ref, { societyId: DEFAULT }, { merge: true });
    updated++;
    count++;
    if (count >= 400) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) {
    await batch.commit();
  }
  console.log(collectionId + ": merged societyId on " + updated + " docs");
}

async function copySocietyConfig() {
  const legacy = await db.collection("settings").doc("society_config").get();
  if (!legacy.exists) {
    console.log("No settings/society_config — skip society_settings copy.");
    return;
  }
  const modern = await db.collection("society_settings").doc(DEFAULT).get();
  if (modern.exists) {
    console.log("society_settings/default already exists — skip copy.");
    return;
  }
  await db.collection("society_settings").doc(DEFAULT).set(
    Object.assign({}, legacy.data(), { societyId: DEFAULT }),
    { merge: true },
  );
  console.log("Copied settings/society_config to society_settings/default");
}

async function main() {
  const collections = [
    "users",
    "blocks",
    "units",
    "visitors",
    "pre_approvals",
    "notices",
    "complaints",
    "daily_staff",
  ];
  await copySocietyConfig();
  for (let i = 0; i < collections.length; i++) {
    await mergeSocietyId(collections[i]);
  }
  console.log("Done.");
  process.exit(0);
}

main().catch(function (e) {
  console.error(e);
  process.exit(1);
});
