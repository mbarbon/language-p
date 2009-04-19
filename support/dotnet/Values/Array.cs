using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class Array : IAny
    {       
        public Array(Runtime runtime)
        {
            array = new List<IAny>();
        }

        public IEnumerator<IAny> GetEnumerator()
        {
            return array.GetEnumerator();
        }

        public virtual void Push(Runtime runtime, IAny item)
        {
            array.Add(item);
        }
        
        public virtual Scalar AsScalar(Runtime runtime) { return new Scalar(runtime, array.Count); }
        public virtual string AsString(Runtime runtime) { return AsScalar(runtime).AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return array.Count; }
        public virtual double AsFloat(Runtime runtime) { return array.Count; }        
        
        protected List<IAny> array;
    }
}
