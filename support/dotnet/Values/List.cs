using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{   
    public class List : Array
    {    
        public List(Runtime runtime) : base(runtime)
        {
        }

        public override Scalar AsScalar(Runtime runtime)
        {
            return array.Count == 0 ? null : array[array.Count - 1].AsScalar(runtime);
        }
    }
}
