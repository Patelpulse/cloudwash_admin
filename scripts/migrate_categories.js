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

async function migrateCategories() {
    console.log('🚀 Starting category migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch categories from backend
        console.log('📥 Fetching categories from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/categories`);
        const categories = response.data;

        console.log(`✅ Found ${categories.length} categories\n`);

        if (categories.length === 0) {
            console.log('⚠️  No categories found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const category of categories) {
            try {
                const categoryData = {
                    name: category.name || '',
                    description: category.description || '',
                    price: category.price || 0,
                    imageUrl: category.imageUrl || '',
                    isActive: category.isActive !== undefined ? category.isActive : true,
                    mongoId: category._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'categories'), categoryData);
                successCount++;
                console.log(`✅ Migrated: ${category.name}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${category.name} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${categories.length}`);
        console.log(`   Success: ${successCount}`);
        console.log(`   Failed: ${errorCount}`);
        console.log('\n🎉 Migration complete!');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        if (error.response) {
            console.error('Response:', error.response.data);
        }
    } finally {
        // Exit the process
        process.exit(0);
    }
}

migrateCategories();
