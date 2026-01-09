import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, serverTimestamp } from 'firebase/firestore';
import axios from 'axios';

const BACKEND_API_URL = 'https://cloudwashapi.onrender.com/api';

const firebaseConfig = {
    apiKey: "AIzaSyDQgMfagJiN16By-sS4fbAM0Kf6omkSRG8",
    authDomain: "cloudwash-6ceb6.firebaseapp.com",
    projectId: "cloudwash-6ceb6",
    storageBucket: "cloudwash-6ceb6.firebasestorage.app",
    messagingSenderId: "864806051234",
    appId: "1:864806051234:web:ce326d49512cc22f8a26fb"
};

async function migrateCities() {
    console.log('🚀 Starting cities migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch cities from backend
        console.log('📥 Fetching cities from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/cities`);
        const cities = response.data;

        console.log(`✅ Found ${cities.length} cities\n`);

        if (cities.length === 0) {
            console.log('⚠️  No cities found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const city of cities) {
            try {
                const cityData = {
                    name: city.name || '',
                    state: city.state || '',
                    country: city.country || 'India',
                    isActive: city.isActive !== undefined ? city.isActive : true,
                    mongoId: city._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'cities'), cityData);
                successCount++;
                console.log(`✅ Migrated: ${city.name || 'Unnamed'}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${city.name || 'Unnamed'} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${cities.length}`);
        console.log(`   Success: ${successCount}`);
        console.log(`   Failed: ${errorCount}`);
        console.log('\n🎉 Migration complete!');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        if (error.response) {
            console.error('Response:', error.response.data);
        }
    } finally {
        process.exit(0);
    }
}

migrateCities();
