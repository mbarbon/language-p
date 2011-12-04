#!/usr/bin/perl -w

print "1..13\n";

print "ok 1\n";

{
    ;
}

print "ok 2\n";

{
    {
        print "ok 3\n";
    }
}

print "ok 4\n";

{
    {
        {
            print "ok 5\n";
        }
    }
}

print "ok 6\n";

{
    {
        print "ok 7\n";

        {
            ;
        }
    }
}

print "ok 8\n";

{
    {
        {
            ;
        }

        print "ok 9\n";
    }
}

print "ok 10\n";

{
    {
        {
            print "ok 11\n";
        }
        {
            print "ok 12\n";
        }
    }
}

print "ok 13\n";
