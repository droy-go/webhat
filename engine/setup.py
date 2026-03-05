from setuptools import setup, find_packages

setup(
    name="webhat-engine",
    version="1.0.0",
    description="Python engine for WebHat interactive comic format",
    author="WebHat Team",
    packages=find_packages(),
    install_requires=[
        "Pillow>=10.0.0",
        "pydub>=0.25.1",
        "pygame>=2.5.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=23.0.0",
            "mypy>=1.0.0",
        ]
    },
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "webhat-engine=webhat_engine.cli:main",
        ]
    },
)
