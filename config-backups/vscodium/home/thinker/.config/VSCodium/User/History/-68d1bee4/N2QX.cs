using System;

class PersonalInformation
{
    public string Name1;
    public int Age1;
    public string Gender1;

    public void Introduce()
    {
        Console.WriteLine("Hello");
        Console.WriteLine("My name is " + Name1);
        Console.WriteLine("I'm " + Age1 + " years old");
        //Console.WriteLine("Gender: " + Gender1);
    }
}

public class MainStuff
{
    public static void Main(string[] args)
    {
        PersonalInformation s1 = new PersonalInformation();

        Console.Write("Enter Name: ");
        s1.Name1 = Console.ReadLine();

        Console.Write("Enter Age: ");
        s1.Age1 = int.Parse(Console.ReadLine());

        //Console.Write("Enter Gender: ");
        //s1.Gender1 = Console.ReadLine();

        s1.Introduce();
    }
}
