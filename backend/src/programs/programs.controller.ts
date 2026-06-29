import { Controller, Get, Post, Body, Req, UseGuards, Param, Delete } from '@nestjs/common';
import { ProgramsService } from './programs.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('programs')
@UseGuards(JwtAuthGuard)
export class ProgramsController {
  constructor(private readonly programsService: ProgramsService) {}

  @Get('custom-exercises')
  async getCustomExercises(@Req() req: any) {
    return this.programsService.getCustomExercises(req.user.sub);
  }

  @Post('custom-exercises')
  async createCustomExercise(@Req() req: any, @Body() body: { name: string; category: string }) {
    return this.programsService.createCustomExercise(req.user.sub, body.name, body.category);
  }

  @Get('scheduled')
  async getScheduledExercises(@Req() req: any) {
    return this.programsService.getScheduledExercises(req.user.sub);
  }

  @Post('scheduled')
  async addScheduledExercise(@Req() req: any, @Body() body: any) {
    return this.programsService.addScheduledExercise(req.user.sub, body);
  }

  @Delete('scheduled/:id')
  async removeScheduledExercise(@Req() req: any, @Param('id') id: string) {
    return this.programsService.removeScheduledExercise(req.user.sub, parseInt(id, 10));
  }
}
