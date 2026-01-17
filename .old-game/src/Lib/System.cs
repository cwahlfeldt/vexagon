using System.Threading.Tasks;

namespace Game
{
    public abstract class System : ISystem
    {
        protected Entities Entities { get; private set; }
        protected PathFinder PathFinder { get; private set; }
        protected Events Events { get; private set; }
        protected Tweener Tweener { get; private set; }
        protected Systems Systems { get; private set; }

        internal void InjectDependencies(SystemDependencies dependencies)
        {
            Entities = dependencies.Entities;
            PathFinder = dependencies.PathFinder;
            Events = dependencies.Events;
            Tweener = dependencies.Tweener;
            Systems = dependencies.Systems;
        }

        // Get other systems when needed
        protected T GetSystem<T>() where T : ISystem
        {
            return Systems.Get<T>();
        }

        public virtual void Initialize() { }
        public virtual async Task Update() { }
        public virtual async void Process(float delta) { }
        public virtual void Cleanup() { }
    }
}
