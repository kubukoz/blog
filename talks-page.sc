//> using scala 3.5.2
//> using toolkit default
//> using toolkit typelevel:default
//> using dep com.lihaoyi::scalatags:0.13.1
//> using dep org.jsoup:jsoup:1.21.2
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import scala.annotation.tailrec

import cats.data.NonEmptyList
import cats.syntax.all.*

extension(s: String) { def nonBreaking = s.replace(" ", "&nbsp;") }

case class Link(
    url: String,
    title: String
)

object Link {
  def slides(url: String) = Link(url, "slides")
  def demo(url: String) = Link(url, "demo")
  def recording(url: String) = Link(url, "recording")
}

case class Location(
    emoji: String,
    full: String
) {
  def remote =
    Location(s"🌎/$emoji", s"Remote / $full")
}

object Location {
  val warsaw =
    Location("🇵🇱", "Warsaw, Poland")

  val wroclaw =
    Location("🇵🇱", "Wrocław, Poland")

  val tokyo =
    Location("🇯🇵", "Tokyo, Japan")

  val berlin =
    Location("🇩🇪", "Berlin, Germany")

  val kiyv =
    Location("🇺🇦", "Kiyv, Ukraine")

  val london =
    Location("🇬🇧", "London, UK")

  val krakow =
    Location("🇵🇱", "Kraków, Poland")

  val lisbon =
    Location("🇵🇹", "Lisbon, Portugal")

  val gdansk =
    Location("🇵🇱", "Gdańsk, Poland")

  val oslo =
    Location("🇳🇴", "Oslo, Norway")

  val boulder =
    Location("🇺🇸", "Boulder, USA")

  val australia =
    Location("🇦🇺", "Australia")

  val penrith =
    Location("🇬🇧", "Penrith, UK")

  val lyon =
    Location("🇫🇷", "Lyon, France")

  val bologna =
    Location("🇮🇹", "Bologna, Italy")

  val ljubljana =
    Location("🇸🇮", "Ljubljana, Slovenia")

  val dublin =
    Location("🇮🇪", "Dublin, Ireland")

  val newyork =
    Location("🇺🇸", "New York, USA")

  val minsk =
    Location("🇧🇾", "Minsk, Belarus")

}

case class Event(
    name: String,
    location: Location
) {
  def remote = copy(location = location.remote)
}

object Event {
  val artOfScala = Event("Art of Scala", Location.warsaw)
  val scalar = Event("Scalar", Location.warsaw)
  val scalaWave = Event("Scala Wave", Location.gdansk)
  val lambdaDays = Event("Lambda Days", Location.krakow)
  val lxScala = Event("LX Scala", Location.lisbon)
  val scalaua = Event("Scala UA", Location.kiyv)
  val ksug = Event("Kraków Scala User Group", Location.krakow)
}

case class TalkEntry(
    title: String,
    years: NonEmptyList[Int],
    events: NonEmptyList[Event],
    links: List[Link]
)

val talks = List(
  TalkEntry(
    "Calico - the functional frontend library you didn't know you needed",
    NonEmptyList.of(2024),
    NonEmptyList.of(Event.artOfScala),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/calico-intro/slides/build/"
      ),
      Link.demo("https://kubukoz.github.io/talks/calico-intro/client/dist/"),
      Link.recording("https://www.youtube.com/watch?v=JP1FRRatcgI")
    )
  ),
  TalkEntry(
    "Foraging into embedded lands - writing Playdate games in Scala",
    NonEmptyList.of(2024),
    NonEmptyList.of(Event.scalar),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/foraging-into-embedded-lands-the-path-to-writing-playdate-games-in-scala"
      ),
      Link.recording("https://www.youtube.com/watch?v=paHZkg8Py1U")
    )
  ),
  TalkEntry(
    "Let's build an IDE!",
    NonEmptyList.of(2023),
    NonEmptyList.of(Event("Scala in the City", Location.london)),
    List(
      Link.slides(
        "https://gist.github.com/kubukoz/5779d7d275e2c2241a1b2535235cf3a2"
      ),
      Link("https://github.com/kubukoz/badlang/tree/smol", "code"),
      Link.recording("https://www.youtube.com/watch?v=VVHDWtcPkk4")
    )
  ),
  TalkEntry(
    "Adventures in the land of Language Servers",
    NonEmptyList.of(2023),
    NonEmptyList.of(Event.lambdaDays),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/adventures-in-the-land-of-language-servers"
      ),
      Link.recording("https://www.youtube.com/watch?v=HF0xVrBZqtI")
    )
  ),
  TalkEntry(
    "Pain-free APIs with Smithy4s",
    NonEmptyList.of(2023),
    NonEmptyList.of(
      Event.scalar,
      Event("Wrocław Scala User Group", Location.wroclaw)
    ),
    List(
      Link(
        "https://speakerdeck.com/kubukoz/pain-free-apis-with-smithy4s",
        "slides (EN)"
      ),
      Link(
        "https://speakerdeck.com/kubukoz/uwolnij-swoje-api-od-bolu-z-smithy4s-c06de564-4646-422e-befd-dabd4579e5e1",
        "slides (PL)"
      ),
      Link.recording("https://www.youtube.com/watch?v=LvCDzDYfgsI")
    )
  ),
  TalkEntry(
    "Things I didn't want to know about JVM bytecode but learned anyway",
    NonEmptyList.of(2022),
    NonEmptyList.of(Event.artOfScala),
    List(
      Link.slides("https://kubukoz.github.io/talks/things-jvm/dist")
    )
  ),
  TalkEntry(
    "Nix for Scala folks",
    NonEmptyList.of(2022),
    NonEmptyList.of(Event.artOfScala),
    List(
      Link.slides("https://speakerdeck.com/kubukoz/nix-for-scala-folks")
    )
  ),
  TalkEntry(
    "Connecting the dots - building and structuring a functional application in Scala",
    NonEmptyList.of(2021),
    NonEmptyList.of(
      Event("YOW! Lambda Jam", Location.australia).remote
    ),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/connecting-the-dots-building-and-structuring-a-functional-application-in-scala"
      ),
      Link.recording("https://www.youtube.com/watch?v=JbMjq8VehLc")
    )
  ),
  TalkEntry(
    "Irresistible party tricks with cats-tagless",
    NonEmptyList.of(2020),
    NonEmptyList.of(Event.scalaua.remote),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/irresistible-party-tricks-with-cats-tagless"
      ),
      Link.recording("https://www.youtube.com/watch?v=rzS9lkg3Cf8")
    )
  ),
  TalkEntry(
    "Keep your sanity with compositional tracing",
    NonEmptyList.of(2020),
    NonEmptyList.of(Event("Typelevel Summit", Location.newyork)),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/keep-your-sanity-with-compositional-tracing"
      ),
      Link.recording("https://www.youtube.com/watch?v=CKS8c1di3Z0")
    )
  ),
  TalkEntry(
    "Introduction to interruption",
    NonEmptyList.of(2019),
    NonEmptyList.of(Event("Functional Scala", Location.london)),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/introduction-to-interruption"
      ),
      Link.recording("https://youtube.com/watch?v=EQWAQF6Yj5Q")
    )
  ),
  TalkEntry(
    "A sky full of streams",
    NonEmptyList.of(2019),
    NonEmptyList.of(
      Event("Scala World", Location.penrith),
      Event("London Scala Community Day", Location.london)
    ),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/a-sky-full-of-streams"
      ),
      Link.recording("https://youtube.com/watch?v=oluPEFlXumw")
    )
  ),
  TalkEntry(
    "Flawless testing for the functional folks",
    NonEmptyList.of(2019),
    NonEmptyList
      .of(Event.lxScala, Event("Scala Italy", Location.bologna)),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/flawless-testing-for-the-functional-folks"
      ),
      Link.recording("https://www.youtube.com/watch?v=v9nv3dfYfw4")
    )
  ),
  TalkEntry(
    "A server is just a function: introduction to http4s",
    NonEmptyList.of(2019),
    NonEmptyList.of(
      Event.ksug,
      Event("Lambda Conf", Location.boulder)
    ),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/a-server-is-just-a-function-introduction-to-http4s"
      ),
      Link("https://www.youtube.com/watch?v=9YsZ8loRVDA", "recording 1"),
      Link("https://www.youtube.com/watch?v=jwKzluH5jFg", "recording 2")
    )
  ),
  TalkEntry(
    "Conquering concurrency with functional programming",
    NonEmptyList.of(2019),
    NonEmptyList.of(Event.scalar, Event.scalaua),
    List(
      Link.slides(
        "https://speakerdeck.com/kubukoz/conquering-concurrency-with-functional-programming"
      ),
      Link("https://youtube.com/watch?v=6z6C1EmxzaI", "recording 1"),
      Link("https://youtube.com/watch?v=fZO2lV2xjEo", "recording 2")
    )
  ),
  TalkEntry(
    "Lightweight, functional microservices with http4s and doobie",
    NonEmptyList.of(2019),
    NonEmptyList.of(Event("Scala Night", Location.minsk)),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/http4s-doobie-micro/slides/"
      ),
      Link.recording("https://youtube.com/watch?v=fQfMiUDsLv4")
    )
  ),
  TalkEntry(
    "Incremental purity",
    NonEmptyList.of(2018),
    NonEmptyList.of(Event("Dublin Scala User Group", Location.dublin)),
    List(
      Link.slides("https://kubukoz.github.io/talks/incremental-purity/slides/")
    )
  ),
  TalkEntry(
    "Typelevel alchemist (workshop)",
    NonEmptyList.of(2018),
    NonEmptyList.of(Event.scalaWave),
    List(
      Link.slides("https://kubukoz.github.io/talks/typelevel-alchemist/slides")
    )
  ),
  TalkEntry(
    "Legacy code from day one",
    NonEmptyList.of(2018),
    NonEmptyList.of(Event("Scala Matsuri", Location.tokyo)),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/legacy-code-from-day-1/slides/#/"
      ),
      Link.recording("https://youtube.com/watch?v=6FYISbNdanE")
    )
  ),
  TalkEntry(
    "Fantastic monads and where to find them",
    NonEmptyList.of(2017, 2018),
    NonEmptyList.of(
      Event.scalaua,
      Event("BeeScala", Location.ljubljana),
      Event("flatMap(Oslo)", Location.oslo),
      Event.lxScala,
      Event("Berlin Scala User Group", Location.berlin)
    ),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/fantastic-monads-and-where-to-find-them/slides/#/"
      ),
      Link("https://youtube.com/watch?v=hOvyL28t0Yc", "recording 1"),
      Link("https://youtube.com/watch?v=HMs_F7LXTak", "recording 2")
    )
  ),
  TalkEntry(
    "7 sins of a Scala beginner",
    NonEmptyList.of(2016, 2017),
    NonEmptyList.of(Event.scalaWave, Event("ScalaIO", Location.lyon)),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/seven-sins-of-a-scala-developer/slides/#/"
      ),
      Link("https://youtu.be/8ZAKrcnQ7Ww", "recording 1"),
      Link("https://youtube.com/watch?v=Z2YzCzfUNNk", "recording 2")
    )
  ),
  TalkEntry(
    "Macro sourcery",
    NonEmptyList.of(2016),
    NonEmptyList.of(
      Event("Functional Tricity", Location.gdansk),
      Event.ksug
    ),
    List(
      Link.slides(
        "https://kubukoz.github.io/talks/macro-sourcery/slides/#/"
      ),
      Link("https://youtube.com/watch?v=-ayx8NIDv4Q", "recording 1"),
      Link("https://youtube.com/watch?v=KvZlYAOtzmU", "recording 2")
    )
  )
)

import scalatags.Text.all.*
import scalatags.Text.tags2.{details, summary}

val columns = List[(String, TalkEntry => Tag)](
  "Title" -> { talk =>
    p(
      b(talk.title),
      span(s" (${talk.years.mkString_("/")})")
    )
  },
  "Events" -> { talk =>
    p(
      talk.events
        .map { e =>
          val nameMain = raw(s"${e.location.emoji}&nbsp;${e.name.nonBreaking}")
          val nameFull = s"${e.name} (${e.location.full})"

          span(
            nameMain,
            title := nameFull
          ) :: Nil
        }
        .toList
        .intercalate(span(", ") :: Nil)
    )
  },
  "Links" -> { talk =>
    span(
      talk.links
        .map { link =>
          span(a(href := link.url, link.title)) :: Nil
        }
        .intercalate(span(" | ") :: Nil)
    )
  }
)

val header = tr(
  columns.map { case (name, _) =>
    th(name)
  }
)

val rows = talks.map { talk =>
  tr(
    columns.map { case (_, f) =>
      td(f(talk))
    }
  )
}

val output = table(
  thead(header),
  tbody(rows)
)

def pretty(html: String): String = {
  val doc: Document = Jsoup.parse(html)
  doc.outputSettings().prettyPrint(true)
  doc.outputSettings().indentAmount(2) // adjust as needed
  doc.body().html()
}

def insertInto(page: String, content: String) = {
  def pattern(inside: String) =
    s"""<!-- GENERATED TALKS BEGIN -->$inside<!-- GENERATED TALKS END -->"""

  pattern("(?s)(.+)").r.replaceAllIn(page, pattern(s"\n$content\n"))
}

val path = os.pwd / "content" / "pages" / "talks.md"

os.write.over(
  path,
  insertInto(os.read(path), pretty(output.render))
)
