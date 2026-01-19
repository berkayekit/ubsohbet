const fs = require('fs');
const path = require('path');

const admin = require('firebase-admin');

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccount.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('serviceAccount.json not found at project root.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();

function loadCityNames() {
  const appDataPath = path.join(__dirname, '..', 'lib', 'app_data.dart');
  const content = fs.readFileSync(appDataPath, 'utf8');
  const listStart = content.indexOf('const List<String> kCityNames = [');
  if (listStart === -1) {
    throw new Error('kCityNames list not found in app_data.dart');
  }
  const listEnd = content.indexOf('];', listStart);
  if (listEnd === -1) {
    throw new Error('kCityNames list end not found.');
  }
  const listContent = content.slice(listStart, listEnd);
  const matches = [...listContent.matchAll(/'([^']+)'/g)];
  const cities = matches.map((match) => match[1].trim()).filter(Boolean);
  if (cities.length === 0) {
    throw new Error('No city names parsed.');
  }
  return cities;
}

async function seedCityStats() {
  const cities = loadCityNames();
  const collection = firestore.collection('city_stats');
  let updated = 0;
  let skipped = 0;

  for (let i = 0; i < cities.length; i += 400) {
    const chunk = cities.slice(i, i + 400);
    const reads = await Promise.all(
      chunk.map((city) => collection.doc(city).get()),
    );
    const batch = firestore.batch();

    reads.forEach((snapshot) => {
      const cityName = snapshot.id;
      const data = snapshot.data();
      const hasCount = data && typeof data.onlineCount === 'number';
      if (hasCount) {
        skipped += 1;
        return;
      }
      batch.set(
        collection.doc(cityName),
        { onlineCount: 0 },
        { merge: true },
      );
      updated += 1;
    });

    await batch.commit();
  }

  console.log(
    `city_stats seed complete. created/updated: ${updated}, skipped: ${skipped}`,
  );
}

seedCityStats()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exit(1);
  });
