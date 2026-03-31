from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.status import HTTP_200_OK
from .models import Task
from .serializers import TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer

    def get_queryset(self):
        queryset = Task.objects.all()
        
        # Search by title
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(title__icontains=search)
        
        # Filter by status
        status = self.request.query_params.get('status', None)
        if status and status != 'ALL':
            queryset = queryset.filter(status=status)
        
        return queryset.order_by('position', '-created_at')

    def update(self, request, *args, **kwargs):
        """Override update to handle recurring task generation"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Check if status is being changed to DONE
        was_done = instance.status == 'DONE'
        is_now_done = request.data.get('status') == 'DONE'
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        # If task just marked as DONE and is recurring, generate next instance
        if not was_done and is_now_done and instance.recurring != 'NONE':
            instance.generate_next_recurring_task()

        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def reorder(self, request):
        """Handle task reordering from drag-and-drop"""
        task_ids = request.data.get('task_ids', [])
        
        # Update position for each task based on new order
        for position, task_id in enumerate(task_ids):
            try:
                task = Task.objects.get(id=task_id)
                task.position = position
                task.save()
            except Task.DoesNotExist:
                continue
        
        return Response({'status': 'reordered'}, status=HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def bulk_actions(self, request):
        """Handle bulk operations like delete"""
        action_type = request.data.get('action')
        ids = request.data.get('ids', [])
        
        if action_type == 'delete':
            Task.objects.filter(id__in=ids).delete()
            return Response({'status': 'deleted'}, status=HTTP_200_OK)
        
        return Response({'error': 'Invalid action'}, status=400)
