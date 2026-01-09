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

async function migrateSubCategories() {
    console.log('🚀 Starting sub-category migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch sub-categories from backend
        console.log('📥 Fetching sub-categories from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/sub-categories`);
        const subCategories = response.data;

        console.log(`✅ Found ${subCategories.length} sub-categories\n`);

        if (subCategories.length === 0) {
            console.log('⚠️  No sub-categories found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const subCategory of subCategories) {
            try {
                const subCategoryData = {
                    name: subCategory.name || '',
                    categoryId: subCategory.categoryId || '',
                    description: subCategory.description || '',
                    imageUrl: subCategory.imageUrl || '',
                    isActive: subCategory.isActive !== undefined ? subCategory.isActive : true,
                    mongoId: subCategory._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'subCategories'), subCategoryData);
                successCount++;
                console.log(`✅ Migrated: ${subCategory.name}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${subCategory.name} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${subCategories.length}`);
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

migrateSubCategories();
