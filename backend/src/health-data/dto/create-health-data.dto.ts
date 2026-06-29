import { IsInt, IsNumber, IsDateString, Min } from 'class-validator';

export class CreateHealthDataDto {
  @IsInt()
  @Min(0)
  steps: number;

  @IsNumber()
  @Min(0)
  activeCalories: number;

  @IsNumber()
  @Min(0)
  basalCalories: number;

  @IsInt()
  @Min(0)
  sleepMinutes: number;

  @IsDateString()
  date: string;
}
