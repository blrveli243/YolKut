import { Controller, Get, Post, Body } from '@nestjs/common';
import { HealthDataService } from './health-data.service';
import { CreateHealthDataDto } from './dto/create-health-data.dto';

@Controller('health-data')
export class HealthDataController {
  constructor(private readonly healthDataService: HealthDataService) {}

  @Post()
  create(@Body() body: CreateHealthDataDto) {
    return this.healthDataService.create({
      userId: 1, // Default user
      steps: body.steps,
      activeCalories: body.activeCalories,
      basalCalories: body.basalCalories,
      sleepMinutes: body.sleepMinutes,
      date: new Date(body.date),
    });
  }

  @Get()
  findAll() {
    return this.healthDataService.findAll(1);
  }
}
