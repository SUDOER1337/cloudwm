using Godot;

public partial class Enemy : CharacterBody2D
{
    [Export] public float Speed = 40f;
    [Export] public float LeftLimit = -50f;
    [Export] public float RightLimit = 50f;

    private int _direction = 1;
    private Vector2 _startPos;

    public override void _Ready()
    {
        _startPos = GlobalPosition;
    }

    public override void _PhysicsProcess(double delta)
    {
        // Patrol left and right
        Velocity = new Vector2(_direction * Speed, 0);

        MoveAndSlide();

        float offset = GlobalPosition.x - _startPos.x;

        if (offset > RightLimit) _direction = -1;
        if (offset < LeftLimit) _direction = 1;
    }
}
