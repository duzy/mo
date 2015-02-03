class IFoo
{
public:
    virtual ~IFoo() {}
    virtual int foo() = 0;
    virtual void bar() = 0;
    void a();
};

void IFoo::a() { this->foo(); }

class Foo : public IFoo
{
    int value;

public:
    explicit Foo(int v) : value(v) {}
    virtual int foo();
    virtual void bar();
    void b();
};

void Foo::b() {}
int Foo::foo() { return value; }
void Foo::bar()
{
    this->a();
    this->b();

    IFoo * i = reinterpret_cast<IFoo*>(this);
    i->a();
    i->foo();
}

class Foobar : public IFoo
{
    int value;
    int factor;

public:
    explicit Foobar(int v, int f) : value(v), factor(f) {}
    virtual int foo() { return value * factor; }
};

int main(int argc, char**argv)
{
    IFoo *ptr = new Foo(100);

    int v = ptr->foo();

    ptr->a();
    reinterpret_cast<Foo*>(ptr)->b();

    delete ptr;
    return 0;
}
