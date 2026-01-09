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

async function migrateBanners() {
    console.log('🚀 Starting banners migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch banners from backend
        console.log('📥 Fetching banners from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/banners`);
        const banners = response.data;

        console.log(`✅ Found ${banners.length} banners\n`);

        if (banners.length === 0) {
            console.log('⚠️  No banners found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const banner of banners) {
            try {
                const bannerData = {
                    title: banner.title || '',
                    description: banner.description || '',
                    imageUrl: banner.imageUrl || '',
                    isActive: banner.isActive !== undefined ? banner.isActive : true,
                    order: banner.order || 0,
                    mongoId: banner._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'banners'), bannerData);
                successCount++;
                console.log(`✅ Migrated: ${banner.title || 'Untitled'}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${banner.title || 'Untitled'} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${banners.length}`);
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

migrateBanners();
