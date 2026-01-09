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

async function migrateAddons() {
    console.log('🚀 Starting addons migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch addons from backend
        console.log('📥 Fetching addons from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/addons`);
        const addons = response.data;

        console.log(`✅ Found ${addons.length} addons\n`);

        if (addons.length === 0) {
            console.log('⚠️  No addons found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const addon of addons) {
            try {
                const addonData = {
                    name: addon.name || '',
                    description: addon.description || '',
                    price: addon.price || 0,
                    imageUrl: addon.imageUrl || '',
                    isActive: addon.isActive !== undefined ? addon.isActive : true,
                    mongoId: addon._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'addons'), addonData);
                successCount++;
                console.log(`✅ Migrated: ${addon.name || 'Unnamed'}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${addon.name || 'Unnamed'} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${addons.length}`);
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

migrateAddons();
