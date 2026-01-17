using Godot;
using Game.Components;

namespace Game
{
    public class DebugSystem : System
    {
        private Node3D _debugNode;
        private Node3D _pathfindingNode;
        private bool _showPathfinding = false;

        public override void Initialize()
        {
            SetupDebugNodes();
            // TogglePathfindingDebug();
            Events.OnUnitActionComplete += OnUnitActionComplete;
        }

        private void OnUnitActionComplete(Entity entity)
        {
            if (_showPathfinding)
                UpdatePathfindingDebug();
        }

        private void SetupDebugNodes()
        {
            _pathfindingNode = new Node3D { Name = "Pathfinding Debug", Position = new Vector3(0.2f, 0.4f, 0.9f) };
            _debugNode = new Node3D { Name = "Debug System" };
            Entities.GetRootNode().AddChild(_debugNode);
            _debugNode.AddChild(_pathfindingNode);
        }

        public void TogglePathfindingDebug()
        {
            _showPathfinding = !_showPathfinding;
            _pathfindingNode.Visible = _showPathfinding;

            if (_showPathfinding)
                UpdatePathfindingDebug();
            else
                ClearPathfindingDebug();
        }

        private void UpdatePathfindingDebug()
        {
            ClearPathfindingDebug();

            // Draw nodes
            foreach (var tile in Entities.GetTiles())
            {
                var coord = tile.Get<Coordinate>();
                var worldPos = HexGrid.HexToWorld(coord);

                // Create node visualization
                var nodeMarker = CreateNodeMarker(worldPos, Entities.IsTileOccupied(coord));
                if (tile.Has<Traversable>())
                    _pathfindingNode.AddChild(nodeMarker);
            }

            // Draw connections
            foreach (var tile in Entities.GetTiles())
            {
                var coord = tile.Get<Coordinate>();
                var worldPos = HexGrid.HexToWorld(coord);

                foreach (var dir in HexGrid.Directions.Values)
                {
                    var neighborCoord = coord + dir;
                    if (PathFinder.HasConnection(coord, neighborCoord))
                    {
                        var neighborWorldPos = HexGrid.HexToWorld(neighborCoord);
                        var connection = CreateConnectionLine(worldPos, neighborWorldPos);
                        _pathfindingNode.AddChild(connection);
                    }
                }
            }
        }

        private Node3D CreateNodeMarker(Vector3 position, bool isOccupied)
        {
            var marker = new CsgSphere3D
            {
                Radius = 0.2f,
                Position = new Vector3(position.X, 0.5f, position.Z),
                Material = new StandardMaterial3D
                {
                    AlbedoColor = isOccupied ? Colors.Red : Colors.Green,
                    Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
                }
            };

            return marker;
        }

        private Node3D CreateConnectionLine(Vector3 from, Vector3 to)
        {
            var line = new MeshInstance3D();
            var immediateGeometry = new ImmediateMesh();

            var material = new StandardMaterial3D
            {
                AlbedoColor = Colors.Blue,
                Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            };

            immediateGeometry.SurfaceBegin(Mesh.PrimitiveType.Lines);
            immediateGeometry.SurfaceAddVertex(new Vector3(from.X, 0.5f, from.Z));
            immediateGeometry.SurfaceAddVertex(new Vector3(to.X, 0.5f, to.Z));
            immediateGeometry.SurfaceEnd();

            line.Mesh = immediateGeometry;
            line.MaterialOverride = material;

            return line;
        }

        private void ClearPathfindingDebug()
        {
            foreach (Node child in _pathfindingNode.GetChildren())
            {
                child.QueueFree();
            }
        }

        public override void Cleanup()
        {
            Events.OnUnitActionComplete -= OnUnitActionComplete;
        }

        private void ShowHexCoordLabels()
        {
            var debugNode = new Node3D
            {
                Name = "Coords Debug",
                Position = new Vector3(0.105f, -0.6f, 0.375f)
            };
            _debugNode.AddChild(debugNode);

            foreach (var tile in Entities.GetTiles())
            {
                // if (tile.Get<TileComponent>().Type == TileType.Blocked)
                //     continue;

                var hexCoord = tile.Get<Coordinate>();
                var labelPos = HexGrid.HexToWorld(hexCoord);

                var coordLabel = new Label3D
                {
                    Text = hexCoord.ToString(),
                    FontSize = 34,
                    PixelSize = 0.01f,
                    Billboard = BaseMaterial3D.BillboardModeEnum.Enabled,
                    Position = new Vector3(labelPos.X, 1.1f, labelPos.Z),
                    Modulate = Colors.Black,
                    Name = hexCoord.ToString()
                };
                debugNode.AddChild(coordLabel);
            }
        }
    }
}
