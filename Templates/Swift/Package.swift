import PackageDescription

let package = Package(
    name: "{{ options.name }}",
    dependencies: [
        {% for dependency in options.dependencies %}
        .Package(url: "{{ dependency.git }}", "{{ dependency.version }}"),
        {% endfor %}
    ]
)
