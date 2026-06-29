import { Test, TestingModule } from '@nestjs/testing';
import { HealthDataService } from './health-data.service';
import { PrismaService } from '../prisma/prisma.service';

describe('HealthDataService', () => {
  let service: HealthDataService;

  const mockPrismaService = {};

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HealthDataService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<HealthDataService>(HealthDataService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
