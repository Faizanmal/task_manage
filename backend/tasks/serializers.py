from rest_framework import serializers
from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    blocked_by_details = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id',
            'title',
            'description',
            'due_date',
            'status',
            'blocked_by',
            'blocked_by_details',
            'recurring',
            'is_recurring_instance',
            'recurring_parent',
            'position',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'is_recurring_instance']

    def get_blocked_by_details(self, obj):
        if obj.blocked_by:
            return {
                'id': obj.blocked_by.id,
                'title': obj.blocked_by.title,
                'status': obj.blocked_by.status,
            }
        return None
