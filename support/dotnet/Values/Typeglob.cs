using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{    
    public class Typeglob
    {
        public Typeglob(Runtime runtime)
        {
            body = new TypeglobBody(runtime);
        }

        public Scalar Scalar
        {
            get { return body.Scalar; }
            set { body.Scalar = value; }
        }

        public Array Array
        {
            get { return body.Array; }
            set { body.Array = value; }
        }

        private TypeglobBody body;
    }

    public class TypeglobBody
    {
        public TypeglobBody(Runtime runtime)
        {
        }

        public Scalar Scalar
        {
            get { return scalar; }
            set { scalar = value; }
        }

        public Array Array
        {
            get { return array; }
            set { array = value; }
        }

        private Scalar scalar;
        private Array array;
    }
}
