import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { NutritionService } from './nutrition.service';
import { AddFoodDto } from './dto/add-food.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('nutrition')
export class NutritionController {
  constructor(private readonly nutritionService: NutritionService) {}

  @Get('daily-summary')
  getDailySummary(@Request() req: any, @Query('date') date: string) {
    const targetDate = date || new Date().toISOString().split('T')[0];
    return this.nutritionService.getDailySummary(req.user.sub, targetDate);
  }

  @Get('search-food')
  searchFood(@Request() req: any, @Query('q') query: string) {
    return this.nutritionService.searchFood(req.user.sub, query);
  }

  @Post('food')
  addFood(@Request() req: any, @Body() dto: AddFoodDto) {
    return this.nutritionService.addFood(req.user.sub, dto);
  }

  @Post('custom-food')
  createCustomFood(@Request() req: any, @Body() dto: any) {
    return this.nutritionService.createCustomFood(req.user.sub, dto);
  }
}
