from django.core.management.base import BaseCommand
from overtime_app.models import Position

class Command(BaseCommand):
    help = 'Создает должности Сотрудник и Руководитель'

    def handle(self, *args, **options):
        positions = ['Сотрудник', 'Руководитель']
        for pos_name in positions:
            pos, created = Position.objects.get_or_create(name=pos_name)
            if created:
                self.stdout.write(f'Создана должность: {pos_name}')
            else:
                self.stdout.write(f'Должность уже существует: {pos_name}')