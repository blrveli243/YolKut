import { Controller, Get, Post, Body, Req, UseGuards } from '@nestjs/common';
import { GoalsService } from './goals.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('goals')
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Post()
  create(@Req() req: any, @Body() createGoalDto: CreateGoalDto) {
    return this.goalsService.create(req.user.sub, createGoalDto);
  }

  @Get()
  findAll(@Req() req: any) {
    return this.goalsService.findAll(req.user.sub);
  }
}
