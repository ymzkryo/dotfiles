class {{_expr_:substitute('{{_input_:name}}', '\w\+', '\u\0', '')}}(viewsets.ViewSet):
    """
    {{_cursor_}}
    """

    def list(self, request):
        """
        GET
        """
        pass

    def create(self, request):
        """
        POST
        """
        pass

    def retrive(self, request, pk=None):
        """
        GET
        """
        pass

    def update(self, request, pk=None):
        """
        PUT
        """
        pass

    def partial_update(self, request, pk=None):
        """
        PATCH
        """
        pass

    def destroy(self, request, pk=None):
        """
        DELETE
        """
        pass
