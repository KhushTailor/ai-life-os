const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

app.post('/api/chat', async (req, res) => {
    try {
        const { message, context } = req.body;
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        // Build system instruction with context
        let systemPrompt = "You are an Intelligent Personal Operating System (Life OS). " +
            "You help the user manage their life, tasks, habits, and finances. " +
            "Be proactive, concise, and helpful. ";

        if (context) {
            systemPrompt += "\n\nUser Context:\n";
            if (context.tasks) systemPrompt += `Tasks: ${JSON.stringify(context.tasks)}\n`;
            if (context.habits) systemPrompt += `Habits: ${JSON.stringify(context.habits)}\n`;
            if (context.finance) systemPrompt += `Finance: ${JSON.stringify(context.finance)}\n`;
        }

        const chat = model.startChat({
            history: [
                { role: "user", parts: [{ text: systemPrompt }] },
                { role: "model", parts: [{ text: "Understood. I am ready to assist you as your Life OS." }] },
            ],
        });

        const result = await chat.sendMessage(message);
        const response = await result.response;
        res.json({ text: response.text() });
    } catch (error) {
        console.error("Error in /api/chat:", error);
        res.status(500).json({ error: "Failed to generate AI response", details: error.message });
    }
});

app.post('/api/categorize', async (req, res) => {
    try {
        const { description } = req.body;
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const prompt = `Categorize this expense description into ONE word from these options: Food, Transport, Shopping, Bills, Entertainment, Health, Other. Description: "${description}"`;
        const result = await model.generateContent(prompt);
        const response = await result.response;
        let category = response.text().trim();
        if (category.includes(' ')) category = category.split(' ')[0];
        console.log(`EXPENSE CATEGORIZED: "${description}" -> ${category}`);
        res.json({ category });
    } catch (error) {
        console.error("Error in /api/categorize:", error);
        res.status(500).json({ error: "Failed to categorize expense" });
    }
});

app.listen(PORT, () => {
    console.log(`Backend proxy running on port ${PORT}`);
});
