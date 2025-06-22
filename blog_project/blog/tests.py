from django.test import TestCase
from .models import Post

# Create your tests here.

class PostModelTest(TestCase):

    def setUp(self):
        Post.objects.create(title="Test Post", content="This is a test.")

    def test_post_content(self):
        post = Post.objects.all().first()
        expected_object_name = f'{post.title}'
        self.assertEqual(expected_object_name, 'Test Post')

class PostListViewTest(TestCase):

    def setUp(self):
        Post.objects.create(title="Another Post", content="More content.")

    def test_view_url_exists_at_proper_location(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
    def test_view_uses_correct_template(self):
        response = self.client.get('/')
        self.assertTemplateUsed(response, 'blog/post_list.html')
