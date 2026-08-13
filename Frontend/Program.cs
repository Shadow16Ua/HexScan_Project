using Photino.NET;
using System;
using System.IO;

namespace HexScan.Frontend
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            // 1. Генеруємо чисті абсолютні шляхи
            string binPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "wwwroot", "index.html"));
            string projPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "wwwroot", "index.html"));

            string finalPath = "";

            // 2. Шукаємо файл
            if (File.Exists(binPath))
                finalPath = binPath;
            else if (File.Exists(projPath))
                finalPath = projPath;

            var window = new PhotinoWindow()
                .SetTitle("HexScan - Local Threat Analyzer")
                .SetSize(1080, 720)
                .SetDevToolsEnabled(true) // F12 для відладки JS/CSS
                .Center()
                .RegisterWebMessageReceivedHandler((object? sender, string message) =>
                {
                    var w = (PhotinoWindow)sender!;

                    // Відповідь-заглушка
                    string mockResponse = """
                    {
                        "status": "suspicious",
                        "threatsFound": 2,
                        "hashes": {
                            "md5": "d41d8cd98f00b204e9800998ecf8427e",
                            "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                        }
                    }
                    """;
                    w.SendWebMessage(mockResponse);
                });

            // 3. Завантажуємо інтерфейс або екран помилки
            if (!string.IsNullOrEmpty(finalPath))
            {
                // Передаємо чистий Windows-шлях без file:///
                window.Load(finalPath);
            }
            else
            {
                // Якщо файлу ніде немає, показуємо екран помилки прямо у UI
                window.LoadRawString($"""
                    <body style='background:#111; color:white; font-family:sans-serif; padding:40px;'>
                        <h2 style='color:#ff4757;'>Помилка: Файл index.html не знайдено!</h2>
                        <p>Я шукав його за такими шляхами:</p>
                        <ul>
                            <li>{binPath}</li>
                            <li>{projPath}</li>
                        </ul>
                        <p>Переконайся, що папка <b>wwwroot</b> створена і всередині є <b>index.html</b>.</p>
                    </body>
                """);
            }

            window.WaitForClose();
        }
    }
}