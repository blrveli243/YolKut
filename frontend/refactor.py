import os

color_map = {
    'Color(0xFF32D74B)': 'AppColors.primary',
    'Color(0xFF10B981)': 'AppColors.primary',
    'Color(0xFF00C896)': 'AppColors.primary',
    'Color(0xFFFF375F)': 'AppColors.error',
    'Color(0xFFFF9F0A)': 'AppColors.warning',
    'Color(0xFFF59E0B)': 'AppColors.warning',
    'Color(0xFF0A84FF)': 'AppColors.info',
    'Color(0xFF3B82F6)': 'AppColors.info',
    'Color(0xFF5E5CE6)': 'AppColors.fat',
    'Color(0xFF64D2FF)': 'AppColors.sugar',
    'Color(0xFF0EA5E9)': 'AppColors.water',
    'Color(0xFF1C1C1E)': 'Theme.of(context).cardColor',
    'Color(0xFF2C2C2E)': 'Theme.of(context).dividerColor',
}

import_statement = "import '../../core/theme/app_colors.dart';\n"

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    for old_color, new_color in color_map.items():
        content = content.replace(f'const {old_color}', new_color)
        content = content.replace(old_color, new_color)

    if content != original_content:
        # Add import if not exists
        if 'app_colors.dart' not in content:
            # find first import and insert after
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i, import_statement.strip())
                    break
            content = '\n'.join(lines)
            
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'Refactored: {filepath}')

def main():
    features_dir = '/Users/velibilir/Desktop/YolKut/frontend/lib/features'
    for root, dirs, files in os.walk(features_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
