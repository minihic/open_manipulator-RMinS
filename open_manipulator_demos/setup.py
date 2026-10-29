from setuptools import find_packages, setup


package_name = 'open_manipulator_demos'


setup(
    name=package_name,
    version='4.0.9',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Pyo',
    maintainer_email='pyo@robotis.com',
    description='MoveIt examples for the OpenManipulator-X.',
    license='Apache 2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'template = open_manipulator_demos.examples.template:main',
            'ex_joint_goal = open_manipulator_demos.examples.ex_joint_goal:main',
            'ex_pose_goal = open_manipulator_demos.examples.ex_pose_goal:main',
            'ex_gripper = open_manipulator_demos.examples.ex_gripper:main',
            'ex_collision_primitive = open_manipulator_demos.examples.ex_collision_primitive:main',
            'ex_utils_fixed = open_manipulator_demos.examples.utils_fixed:main',
        ],
    },
)
