import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AddFoodDto } from './dto/add-food.dto';

@Injectable()
export class NutritionService {
  constructor(private prisma: PrismaService) {}

  // Harris-Benedict BMR Calculation
  private calculateBMR(weight: number | null, height: number | null, age: number | null, gender: string | null): number {
    if (!weight || !height || !age || !gender) {
      return 2000; // Fallback if profile is incomplete
    }
    
    // Male: 88.362 + (13.397 x weight) + (4.799 x height) - (5.677 x age)
    // Female: 447.593 + (9.247 x weight) + (3.098 x height) - (4.330 x age)
    if (gender.toLowerCase() === 'erkek' || gender.toLowerCase() === 'male') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  private mockFoods = [
    // Kahvaltılıklar & Temel Ürünler
    { name: 'Yulaf Ezmesi (100g)', calories: 389, protein: 16.9, carbs: 66.3, fat: 6.9, sugar: 0 },
    { name: 'Yumurta (1 Adet Haşlanmış)', calories: 78, protein: 6, carbs: 0.6, fat: 5, sugar: 0.6 },
    { name: 'Tam Buğday Ekmeği (1 Dilim)', calories: 69, protein: 3.6, carbs: 11.6, fat: 0.9, sugar: 1.4 },
    { name: 'Beyaz Ekmek (1 Dilim)', calories: 90, protein: 2.6, carbs: 18.5, fat: 1.0, sugar: 1.5 },
    { name: 'Süt (1 Bardak - 200ml)', calories: 122, protein: 8, carbs: 12, fat: 4.8, sugar: 12 },
    { name: 'Süzme Peynir (100g)', calories: 98, protein: 11, carbs: 3, fat: 4, sugar: 3 },
    { name: 'Beyaz Peynir (Tam Yağlı 100g)', calories: 310, protein: 19, carbs: 2.5, fat: 25, sugar: 2 },
    { name: 'Kaşar Peyniri (100g)', calories: 350, protein: 27, carbs: 2.5, fat: 26, sugar: 1 },
    { name: 'Zeytin (10 Adet)', calories: 42, protein: 0.2, carbs: 1, fat: 4.5, sugar: 0 },
    { name: 'Bal (1 Yemek Kaşığı)', calories: 64, protein: 0.1, carbs: 17, fat: 0, sugar: 17 },
    { name: 'Tereyağı (1 Yemek Kaşığı)', calories: 102, protein: 0.1, carbs: 0.1, fat: 11.5, sugar: 0.1 },
    { name: 'Kaymak (1 Yemek Kaşığı - 20g)', calories: 116, protein: 0.2, carbs: 0.5, fat: 12, sugar: 0.5 },
    { name: 'Menemen (1 Porsiyon)', calories: 175, protein: 9, carbs: 6, fat: 12, sugar: 4 },

    // Türk Kebapları & Pide & Dönerler
    { name: 'Et Döner Dürüm (1 Adet)', calories: 450, protein: 32, carbs: 48, fat: 16, sugar: 2 },
    { name: 'Tavuk Döner Dürüm (1 Adet)', calories: 390, protein: 28, carbs: 45, fat: 12, sugar: 1.5 },
    { name: 'Et Döner Porsiyon (100g)', calories: 220, protein: 24, carbs: 1.5, fat: 13, sugar: 0.5 },
    { name: 'Tavuk Döner Porsiyon (100g)', calories: 180, protein: 21, carbs: 1, fat: 9, sugar: 0 },
    { name: 'İskender Kebap (1 Porsiyon)', calories: 750, protein: 38, carbs: 54, fat: 42, sugar: 4 },
    { name: 'Adana Kebap Porsiyon (1 Porsiyon)', calories: 620, protein: 35, carbs: 15, fat: 48, sugar: 2 },
    { name: 'Urfa Kebap Porsiyon (1 Porsiyon)', calories: 600, protein: 34, carbs: 15, fat: 46, sugar: 2 },
    { name: 'Tavuk Şiş Porsiyon (1 Porsiyon)', calories: 340, protein: 36, carbs: 12, fat: 14, sugar: 1 },
    { name: 'Beyti Sarma (1 Porsiyon)', calories: 820, protein: 42, carbs: 60, fat: 48, sugar: 3 },
    { name: 'Lahmacun (1 Adet)', calories: 240, protein: 12, carbs: 32, fat: 8, sugar: 1.5 },
    { name: 'Kıymalı Pide (1 Adet)', calories: 580, protein: 24, carbs: 75, fat: 20, sugar: 3 },
    { name: 'Kaşarlı Pide (1 Adet)', calories: 500, protein: 20, carbs: 72, fat: 16, sugar: 2 },
    { name: 'Karışık Pide (1 Adet)', calories: 650, protein: 28, carbs: 78, fat: 24, sugar: 3.5 },

    // Hamburgerler & Pizza & Fast Food
    { name: 'Hamburger (1 Adet Klasik)', calories: 250, protein: 12, carbs: 31, fat: 9, sugar: 5 },
    { name: 'Cheeseburger (1 Adet)', calories: 300, protein: 15, carbs: 33, fat: 12, sugar: 6 },
    { name: 'Double Cheeseburger (1 Adet)', calories: 480, protein: 26, carbs: 35, fat: 24, sugar: 7 },
    { name: 'Tavuk Burger (1 Adet)', calories: 350, protein: 16, carbs: 42, fat: 13, sugar: 5 },
    { name: 'Pizza Karışık (1 Dilim)', calories: 285, protein: 12, carbs: 36, fat: 10, sugar: 3 },
    { name: 'Pizza Margherita (1 Dilim)', calories: 250, protein: 10, carbs: 34, fat: 8, sugar: 2.5 },
    { name: 'Patates Kızartması (Orta Boy)', calories: 365, protein: 4, carbs: 48, fat: 17, sugar: 0.5 },
    { name: 'Hot Dog / Sosisli Sandviç (1 Adet)', calories: 290, protein: 10, carbs: 28, fat: 16, sugar: 4 },
    { name: 'Falafel (1 Porsiyon - 4 Adet)', calories: 260, protein: 8, carbs: 30, fat: 12, sugar: 1 },
    { name: 'Çıtır Tavuk Kovası (1 Porsiyon)', calories: 520, protein: 32, carbs: 38, fat: 26, sugar: 1 },

    // Et, Tavuk, Balık
    { name: 'Izgara Tavuk Göğsü (100g)', calories: 165, protein: 31, carbs: 0, fat: 3.6, sugar: 0 },
    { name: 'Somon Izgara (100g)', calories: 208, protein: 22, carbs: 0, fat: 13, sugar: 0 },
    { name: 'Dana Antrikot (100g)', calories: 250, protein: 26, carbs: 0, fat: 17, sugar: 0 },
    { name: 'Ton Balığı (Konserve 100g)', calories: 132, protein: 28, carbs: 0, fat: 2, sugar: 0 },
    { name: 'Köfte (1 Porsiyon - 4 Adet)', calories: 350, protein: 25, carbs: 10, fat: 20, sugar: 1 },
    { name: 'Kavurma (100g)', calories: 345, protein: 21, carbs: 0, fat: 28, sugar: 0 },
    { name: 'Kuzu Pirzola (100g)', calories: 290, protein: 24, carbs: 0, fat: 21, sugar: 0 },
    { name: 'Hindi Göğsü (100g)', calories: 135, protein: 30, carbs: 0, fat: 1, sugar: 0 },

    // Ev Yemekleri & Çorbalar
    { name: 'Mercimek Çorbası (1 Kase)', calories: 140, protein: 8, carbs: 22, fat: 3, sugar: 1 },
    { name: 'Ezogelin Çorbası (1 Kase)', calories: 150, protein: 7.5, carbs: 24, fat: 3.5, sugar: 1 },
    { name: 'Tarhana Çorbası (1 Kase)', calories: 120, protein: 5, carbs: 20, fat: 2.5, sugar: 1.5 },
    { name: 'Kuru Fasulye (1 Porsiyon)', calories: 280, protein: 14, carbs: 42, fat: 6, sugar: 2 },
    { name: 'Nohut Yemeği (1 Porsiyon)', calories: 260, protein: 12, carbs: 40, fat: 5, sugar: 2 },
    { name: 'Zeytin Yağlı Yaprak Sarması (5 Adet)', calories: 180, protein: 2.5, carbs: 32, fat: 4.5, sugar: 1 },
    { name: 'Karnıyarık (1 Adet)', calories: 210, protein: 11, carbs: 12, fat: 14, sugar: 5 },
    { name: 'Mantı (1 Porsiyon)', calories: 410, protein: 14, carbs: 62, fat: 12, sugar: 3 },
    { name: 'Biber Dolması (1 Adet)', calories: 150, protein: 5, carbs: 22, fat: 5, sugar: 2.5 },
    { name: 'Taze Fasulye (1 Porsiyon)', calories: 95, protein: 3, carbs: 12, fat: 4, sugar: 5 },
    { name: 'Mercimek Köftesi (1 Adet)', calories: 75, protein: 2.5, carbs: 12, fat: 2, sugar: 0.8 },
    { name: 'İçli Köfte (1 Adet)', calories: 180, protein: 8, carbs: 20, fat: 8, sugar: 1 },
    { name: 'Mücver (1 Adet)', calories: 90, protein: 3.5, carbs: 10, fat: 4, sugar: 2 },

    // Karbonhidratlar & Pilavlar
    { name: 'Pirinç Pilavı (100g - Pişmiş)', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, sugar: 0.1 },
    { name: 'Bulgur Pilavı (100g - Pişmiş)', calories: 83, protein: 3.1, carbs: 18.6, fat: 0.2, sugar: 0.1 },
    { name: 'Makarna (100g - Pişmiş)', calories: 158, protein: 5.8, carbs: 31, fat: 0.9, sugar: 0.5 },
    { name: 'Erişte (100g - Pişmiş)', calories: 180, protein: 6, carbs: 36, fat: 1.2, sugar: 0.8 },
    { name: 'Haşlanmış Patates (100g)', calories: 86, protein: 1.7, carbs: 20, fat: 0.1, sugar: 0.8 },
    { name: 'Basmati Pirinç Pilavı (100g - Pişmiş)', calories: 121, protein: 3.5, carbs: 25, fat: 0.4, sugar: 0 },
    { name: 'Karabuğday (Greçka - 100g Pişmiş)', calories: 92, protein: 3.4, carbs: 20, fat: 0.6, sugar: 0 },
    { name: 'Kinoa (100g - Pişmiş)', calories: 120, protein: 4.4, carbs: 21.3, fat: 1.9, sugar: 0.9 },

    // Hamur İşleri (Fırın)
    { name: 'Simit (1 Adet)', calories: 320, protein: 9, carbs: 58, fat: 6, sugar: 3 },
    { name: 'Peynirli Poğaça (1 Adet)', calories: 220, protein: 5, carbs: 26, fat: 11, sugar: 2 },
    { name: 'Sade Açma (1 Adet)', calories: 310, protein: 6, carbs: 42, fat: 14, sugar: 4 },
    { name: 'Ispanaklı Börek (1 Dilim)', calories: 280, protein: 7, carbs: 32, fat: 13, sugar: 2.5 },
    { name: 'Su Böreği (1 Dilim)', calories: 340, protein: 8, carbs: 36, fat: 18, sugar: 1.5 },

    // Salatalar & Mezeler
    { name: 'Çoban Salatası (1 Porsiyon)', calories: 85, protein: 1.5, carbs: 8, fat: 5, sugar: 4 },
    { name: 'Sezar Salata (1 Porsiyon)', calories: 320, protein: 16, carbs: 12, fat: 24, sugar: 2 },
    { name: 'Ton Balıklı Salata (1 Porsiyon)', calories: 240, protein: 22, carbs: 8, fat: 12, sugar: 3 },
    { name: 'Cacık (1 Kase)', calories: 75, protein: 4, carbs: 5, fat: 4, sugar: 3.5 },
    { name: 'Haydari (1 Yemek Kaşığı)', calories: 45, protein: 1.5, carbs: 1.2, fat: 3.8, sugar: 1 },
    { name: 'Humus (1 Yemek Kaşığı)', calories: 70, protein: 2.2, carbs: 6.5, fat: 3.8, sugar: 0.5 },
    { name: 'Kısır (1 Porsiyon)', calories: 180, protein: 4, carbs: 28, fat: 6, sugar: 2 },

    // Meyve ve Sebzeler
    { name: 'Muz (1 Adet Orta)', calories: 105, protein: 1.3, carbs: 27, fat: 0.3, sugar: 14 },
    { name: 'Elma (1 Adet Orta)', calories: 95, protein: 0.5, carbs: 25, fat: 0.3, sugar: 19 },
    { name: 'Portakal (1 Adet Orta)', calories: 62, protein: 1.2, carbs: 15, fat: 0.2, sugar: 12 },
    { name: 'Çilek (100g)', calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, sugar: 4.9 },
    { name: 'Karpuz (1 Porsiyon - 200g)', calories: 60, protein: 1.2, carbs: 15, fat: 0.3, sugar: 12 },
    { name: 'Brokoli (100g - Haşlanmış)', calories: 35, protein: 2.4, carbs: 7.2, fat: 0.4, sugar: 1.4 },
    { name: 'Ispanak (100g - Çiğ)', calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, sugar: 0.4 },
    { name: 'Havuç (1 Adet Orta)', calories: 25, protein: 0.6, carbs: 6, fat: 0.1, sugar: 3 },
    { name: 'Domates (1 Adet Orta)', calories: 22, protein: 1, carbs: 4.8, fat: 0.2, sugar: 3.2 },

    // Atıştırmalıklar, Tohumlar & Takviyeler
    { name: 'Fıstık Ezmesi (1 Yemek Kaşığı)', calories: 94, protein: 4, carbs: 3, fat: 8, sugar: 1 },
    { name: 'Badem (1 Avuç - 30g)', calories: 164, protein: 6, carbs: 6, fat: 14, sugar: 1 },
    { name: 'Ceviz (1 Avuç - 30g)', calories: 185, protein: 4.3, carbs: 4, fat: 18.5, sugar: 0.7 },
    { name: 'Fındık (1 Avuç - 30g)', calories: 190, protein: 4.5, carbs: 5, fat: 18, sugar: 1 },
    { name: 'Kaju (1 Avuç - 30g)', calories: 165, protein: 5.5, carbs: 9, fat: 13, sugar: 1.8 },
    { name: 'Chia Tohumu (1 Yemek Kaşığı - 15g)', calories: 73, protein: 2.5, carbs: 6, fat: 4.6, sugar: 0 },
    { name: 'Protein Bar (1 Adet - 60g)', calories: 220, protein: 20, carbs: 22, fat: 8, sugar: 2 },
    { name: 'Post-WOD Protein Shake (1 Ölçek)', calories: 120, protein: 24, carbs: 3, fat: 1, sugar: 1 },

    // Tatlılar (Kaçamaklar)
    { name: 'Fıstıklı Baklava (1 Adet - 40g)', calories: 160, protein: 2, carbs: 20, fat: 8, sugar: 15 },
    { name: 'Fırın Sütlaç (1 Kase)', calories: 280, protein: 6.5, carbs: 48, fat: 6, sugar: 36 },
    { name: 'Künefe (1 Porsiyon)', calories: 450, protein: 8, carbs: 58, fat: 20, sugar: 42 },
    { name: 'Kazandibi (1 Porsiyon)', calories: 220, protein: 4.5, carbs: 38, fat: 5, sugar: 28 },
    { name: 'Revani (1 Dilim)', calories: 320, protein: 5, carbs: 55, fat: 8, sugar: 44 },
    { name: 'Çikolatalı Sufle (1 Adet)', calories: 380, protein: 6, carbs: 44, fat: 20, sugar: 32 },
    { name: 'Çikolata (1 Kare - 10g)', calories: 55, protein: 0.7, carbs: 6, fat: 3.3, sugar: 5.5 },

    // İçecekler
    { name: 'Su (330ml Bardak)', calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 },
    { name: 'Ayran (200ml Bardak)', calories: 76, protein: 4, carbs: 5.6, fat: 4, sugar: 4 },
    { name: 'Kola (330ml Kutu)', calories: 139, protein: 0, carbs: 35, fat: 0, sugar: 35 },
    { name: 'Kola Zero (330ml Kutu)', calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 },
    { name: 'Şekersiz Çay (1 Çay Bardağı)', calories: 1, protein: 0.1, carbs: 0.2, fat: 0, sugar: 0 },
    { name: 'Şekersiz Türk Kahvesi (1 Fincan)', calories: 2, protein: 0.2, carbs: 0.3, fat: 0.1, sugar: 0 },
    { name: 'Taze Portakal Suyu (200ml Bardak)', calories: 90, protein: 1.4, carbs: 21, fat: 0.4, sugar: 18 },
    { name: 'Şalgam Suyu (200ml Bardak)', calories: 10, protein: 0.5, carbs: 1.5, fat: 0.1, sugar: 0.5 },
  ];

  private normalizeString(str: string): string {
    return str
      .toLowerCase()
      .replace(/ı/g, 'i')
      .replace(/ş/g, 's')
      .replace(/ğ/g, 'g')
      .replace(/ü/g, 'u')
      .replace(/ç/g, 'c')
      .replace(/ö/g, 'o');
  }

  async searchFood(userId: number, query: string) {
    if (!query) {
      // If no query, return user's custom foods anyway
      const customFoods = await this.prisma.customFood.findMany({
        where: { userId }
      });
      return customFoods.map(f => ({ ...f, isCustom: true }));
    }
    const normalizedQuery = this.normalizeString(query);
    
    // Custom foods
    const customFoods = await this.prisma.customFood.findMany({
      where: { userId }
    });
    
    const filteredCustom = customFoods.filter(f => 
      this.normalizeString(f.name).includes(normalizedQuery)
    );

    const staticFoods = this.mockFoods.filter(f => 
      this.normalizeString(f.name).includes(normalizedQuery)
    );

    // Combine them, marking custom foods so the UI can show a badge
    const formattedCustom = filteredCustom.map(f => ({ ...f, isCustom: true }));
    const formattedStatic = staticFoods.map(f => ({ ...f, isCustom: false }));

    return [...formattedCustom, ...formattedStatic];
  }

  async getDailySummary(userId: number, dateStr: string) {
    const targetDate = new Date(dateStr);
    targetDate.setUTCHours(0, 0, 0, 0);
    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const bmr = this.calculateBMR(user?.weight ?? null, user?.height ?? null, user?.age ?? null, user?.gender ?? null);
    const activityLevel = user?.activityLevel ?? 1.2;
    const tdee = bmr * activityLevel;

    // Advanced Goal Logic
    let targetCalories = tdee;
    let proteinTarget = 150;
    let carbsTarget = 200;
    let fatTarget = 70;
    let goalType = 'maintain';

    let dailyGoal = user?.dailyGoal?.toLowerCase() ?? 'koruma';

    if (user?.targetWeight && user?.targetDays && user?.weight) {
      const weightDiff = user.weight - user.targetWeight; // > 0 means losing weight
      const totalCalorieDiff = weightDiff * 7700;
      const dailyDeficit = totalCalorieDiff / user.targetDays;
      targetCalories = tdee - dailyDeficit;

      // Safety limits
      const isMale = user.gender?.toLowerCase() === 'erkek';
      const safeMin = isMale ? 1500 : 1200;
      if (targetCalories < safeMin) {
        targetCalories = safeMin;
      }
    } else {
      // If no strict targets, apply generic +300/-300 based on dailyGoal
      if (dailyGoal === 'zayıflamak') {
        targetCalories = tdee - 500;
      } else if (dailyGoal === 'kilo almak') {
        targetCalories = tdee + 500;
      } else if (dailyGoal === 'kaslanmak') {
        targetCalories = tdee + 300; // Lean bulk
      }
    }

    // Dynamic Macros based on explicit dailyGoal or weight diff
    if (dailyGoal === 'zayıflamak' || (user?.targetWeight && user!.weight! > user!.targetWeight!)) {
      goalType = 'lose';
      // Losing weight: 40% Protein, 35% Carbs, 25% Fat
      proteinTarget = (targetCalories * 0.40) / 4;
      carbsTarget = (targetCalories * 0.35) / 4;
      fatTarget = (targetCalories * 0.25) / 9;
    } else if (dailyGoal === 'kaslanmak') {
      goalType = 'muscle';
      // Building muscle (lean bulk): 35% Protein, 45% Carbs, 20% Fat
      proteinTarget = (targetCalories * 0.35) / 4;
      carbsTarget = (targetCalories * 0.45) / 4;
      fatTarget = (targetCalories * 0.20) / 9;
    } else if (dailyGoal === 'kilo almak' || (user?.targetWeight && user!.weight! < user!.targetWeight!)) {
      goalType = 'gain';
      // Gaining weight: 30% Protein, 50% Carbs, 20% Fat
      proteinTarget = (targetCalories * 0.30) / 4;
      carbsTarget = (targetCalories * 0.50) / 4;
      fatTarget = (targetCalories * 0.20) / 9;
    } else {
      goalType = 'maintain';
      // Maintenance: 30% Protein, 40% Carbs, 30% Fat
      proteinTarget = (targetCalories * 0.30) / 4;
      carbsTarget = (targetCalories * 0.40) / 4;
      fatTarget = (targetCalories * 0.30) / 9;
    }

    const healthData = await this.prisma.healthData.findFirst({
      where: {
        userId,
        date: {
          gte: targetDate,
          lt: nextDate,
        }
      }
    });

    const activeCalories = healthData?.activeCalories || 0;

    const foodLogs = await this.prisma.foodLog.findMany({
      where: {
        userId,
        date: {
          gte: targetDate,
          lt: nextDate,
        }
      }
    });

    let consumedCalories = 0;
    let consumedProtein = 0;
    let consumedCarbs = 0;
    let consumedFat = 0;
    let consumedSugar = 0;

    for (const food of foodLogs) {
      consumedCalories += food.calories;
      consumedProtein += food.protein;
      consumedCarbs += food.carbs;
      consumedFat += food.fat;
      consumedSugar += food.sugar;
    }

    const netCalories = consumedCalories - (bmr + activeCalories);

    return {
      date: targetDate.toISOString().split('T')[0],
      goalType,
      bmr,
      tdee,
      targetCalories,
      activityLevel,
      activeCalories,
      consumedCalories,
      netCalories,
      macros: {
        protein: consumedProtein,
        carbs: consumedCarbs,
        fat: consumedFat,
        sugar: consumedSugar,
      },
      targets: {
        protein: proteinTarget,
        carbs: carbsTarget,
        fat: fatTarget,
        sugar: 50, // standard target
      },
      foodLogs,
    };
  }

  async addFood(userId: number, dto: AddFoodDto) {
    return this.prisma.foodLog.create({
      data: {
        userId,
        name: dto.name,
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbs,
        fat: dto.fat,
        sugar: dto.sugar,
        date: new Date(dto.date),
      }
    });
  }

  async createCustomFood(userId: number, dto: any) {
    return this.prisma.customFood.create({
      data: {
        userId,
        name: dto.name,
        ingredients: dto.ingredients,
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbs,
        fat: dto.fat,
        sugar: dto.sugar,
      }
    });
  }
}
