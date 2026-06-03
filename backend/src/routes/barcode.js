import { Router } from 'express';
import { GoogleGenerativeAI } from '@google/generative-ai';

const router = Router();
const geminiApiKey = process.env.GEMINI_API_KEY;

router.post('/lookup', async (req, res) => {
  const { code, apiKey } = req.body || {};
  if (!code) {
    return res.status(400).json({ error: 'barcode required' });
  }

  const activeApiKey = apiKey || geminiApiKey;
  let productInfo = null;

  try {
    // 1. First, attempt Open Food Facts Lookup (ideal for foods/beverages)
    const offResponse = await fetch(`https://world.openfoodfacts.org/api/v0/product/${code}.json`);
    if (offResponse.ok) {
      const data = await offResponse.json();
      if (data.status === 1 && data.product) {
        const p = data.product;
        productInfo = {
          source: 'open_food_facts',
          name: p.product_name || 'Unknown Food Item',
          brand: p.brands || 'Unknown Brand',
          imageUrl: p.image_url || '',
          ingredients: p.ingredients_text || 'No ingredients listed',
          nutrition: {
            energy: p.nutriments?.['energy-kcal_100g'] || p.nutriments?.energy_100g || 0,
            fat: p.nutriments?.fat_100g || 0,
            sugar: p.nutriments?.sugars_100g || 0,
            salt: p.nutriments?.salt_100g || 0,
            proteins: p.nutriments?.proteins_100g || 0,
            carbs: p.nutriments?.carbohydrates_100g || 0,
          },
          nutriscore: p.nutriscore_grade || 'unknown',
        };
      }
    }
  } catch (err) {
    console.warn('Open Food Facts API error:', err);
  }

  // 2. Perform Gemini lookup / analysis
  if (!activeApiKey) {
    // If no Gemini key is available, return whatever we got from Open Food Facts or a basic stub
    if (productInfo) {
      return res.json({
        ...productInfo,
        analysis: {
          summary: 'Open Food Facts data retrieved. (Gemini analysis unavailable without API key)',
          rating: 5,
          suitability: ['N/A'],
          alternatives: [],
        }
      });
    } else {
      return res.json({
        source: 'none',
        name: `Product (${code})`,
        brand: 'Generic',
        imageUrl: '',
        ingredients: 'Unknown',
        nutrition: {},
        analysis: {
          summary: 'No details found for this barcode. Add a Gemini API key to enable AI-powered product search.',
          rating: 0,
          suitability: [],
          alternatives: [],
        }
      });
    }
  }

  try {
    const client = new GoogleGenerativeAI(activeApiKey);
    const model = client.getGenerativeModel({ model: 'gemini-1.5-flash' });

    let prompt = '';
    if (productInfo) {
      prompt = `
        Analyze the following food product details:
        Name: ${productInfo.name}
        Brand: ${productInfo.brand}
        Ingredients: ${productInfo.ingredients}
        Nutrition (per 100g): Calories: ${productInfo.nutrition.energy} kcal, Fat: ${productInfo.nutrition.fat}g, Sugar: ${productInfo.nutrition.sugar}g, Salt: ${productInfo.nutrition.salt}g, Proteins: ${productInfo.nutrition.proteins}g, Carbs: ${productInfo.nutrition.carbs}g
        Nutriscore: ${productInfo.nutriscore}

        Please perform a food data analysis and provide a JSON response (strictly JSON without markdown blocks) containing:
        {
          "summary": "Short 2-3 sentence overview of how healthy/unhealthy this product is",
          "rating": 8, // A score from 1-10 on healthiness
          "suitability": ["Vegan", "Gluten-Free", "Avoid for Diabetics"], // Dietary flags
          "ingredientsAnalysis": "Short breakdown of dangerous additives, sugar contents or beneficial ingredients",
          "alternatives": ["Suggested healthier alternative 1", "Suggested healthier alternative 2"]
        }
      `;
    } else {
      prompt = `
        A user scanned the barcode "${code}". Since this is not a food item or wasn't found in the food database, perform a general search/lookup based on your knowledge base.
        Identify the potential product associated with barcode "${code}". If it's a known format (ISBN, UPC, EAN), explain what type of product it usually matches.

        Please respond with a JSON object (strictly JSON, no formatting or markdown backticks) containing:
        {
          "name": "Identified Product Name or Category (e.g. Book, Electronic, Drink)",
          "brand": "Manufacturer/Publisher/Brand name",
          "ingredients": "N/A or key materials",
          "summary": "Description of what this product is, its functions, or properties",
          "rating": 7, // Score from 1-10 on quality/popularity
          "suitability": ["Suitable for..."],
          "alternatives": ["Alternative brand/option 1", "Alternative brand/option 2"]
        }
      `;
    }

    const result = await model.generateContent(prompt);
    const responseText = result.response.text().trim();
    
    // Clean up response text if it contains markdown markers
    let jsonText = responseText;
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/^```json\s*/, '').replace(/```$/, '').trim();
    }

    const aiAnalysis = JSON.parse(jsonText);

    if (productInfo) {
      return res.json({
        ...productInfo,
        analysis: aiAnalysis,
      });
    } else {
      return res.json({
        source: 'gemini_lookup',
        name: aiAnalysis.name || `Product (${code})`,
        brand: aiAnalysis.brand || 'Unknown Brand',
        imageUrl: '',
        ingredients: aiAnalysis.ingredients || 'Unknown',
        nutrition: {},
        analysis: {
          summary: aiAnalysis.summary || 'Product details generated by Gemini.',
          rating: aiAnalysis.rating || 5,
          suitability: aiAnalysis.suitability || [],
          alternatives: aiAnalysis.alternatives || [],
        }
      });
    }
  } catch (err) {
    console.error('Gemini barcode analysis error:', err);
    // Return basic info if Gemini parsing fails
    return res.json({
      source: productInfo ? 'open_food_facts' : 'none',
      name: productInfo?.name || `Product (${code})`,
      brand: productInfo?.brand || 'Unknown',
      imageUrl: productInfo?.imageUrl || '',
      ingredients: productInfo?.ingredients || 'Unknown',
      nutrition: productInfo?.nutrition || {},
      analysis: {
        summary: 'Error analyzing product with Gemini AI. ' + err.message,
        rating: productInfo ? 5 : 0,
        suitability: [],
        alternatives: [],
      }
    });
  }
});

export default router;
