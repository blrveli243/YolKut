# Architecture Constitution

## 1. Overview
This project is an end-to-end mobile application for personal development, task management, and Apple Health calorie/step tracking.

## 2. Core Technologies
- **Frontend**: Flutter + Riverpod
- **Backend**: Node.js + NestJS + TypeScript
- **Database**: PostgreSQL (via Docker)
- **ORM**: Prisma

## 3. General Principles
- **Language**: All database tables, variables, file names, and function names MUST be in English.
- **Modularity**: The project should be divided into independent, easily upgradable modules.
- **Clean Architecture**: Separation of concerns between UI, Business Logic, and Data layers.

## 4. Frontend (Flutter) Architecture
- **Architecture**: Feature-First structure.
- **Directory Structure**:
  - `lib/core/`: Contains core utilities, API clients, themes, and shared components.
  - `lib/features/`: Contains feature modules. Each feature (e.g., `health`, `tasks`) should have its own UI, providers, and repositories.
- **State Management**: Riverpod (`flutter_riverpod`). We will use `StateNotifier` and providers to handle business logic.
- **Data Fetching**: `dio` for HTTP requests, `health` package for Apple Health integration.

## 5. Backend (NestJS) Architecture
- **Architecture**: NestJS modular architecture.
- **Directory Structure**:
  - `src/health-data/`: Module, Controller, and Service for handling Apple Health metrics.
  - `src/tasks/`: Module, Controller, and Service for handling user tasks.
- **Database Schema**: Managed by Prisma (`schema.prisma`).
- **Models**:
  - `User`: id, email, password, createdAt
  - `HealthData`: id, userId, steps, activeCalories, basalCalories, sleepMinutes, date
  - `Task`: id, userId, title, isCompleted, date
