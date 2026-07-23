import { IsNumber, IsOptional, IsDateString } from 'class-validator';

export class CreateRunDto {
  @IsNumber()
  distanceKm: number;

  @IsNumber()
  elapsedSeconds: number;

  @IsOptional()
  @IsNumber()
  targetSpeedKmH?: number;

  @IsOptional()
  @IsNumber()
  averageSpeedKmH?: number;

  @IsOptional()
  @IsDateString()
  date?: string;
}
