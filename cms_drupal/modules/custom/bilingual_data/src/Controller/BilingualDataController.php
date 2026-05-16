<?php

namespace Drupal\bilingual_data\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Database\Database;
use Symfony\Component\HttpFoundation\Request;

class BilingualDataController extends ControllerBase {

  public function list(Request $request) {
    $page = max(0, (int) $request->query->get('page', 0));
    $limit = 50;
    $offset = $page * $limit;

    $keyword = trim((string) $request->query->get('keyword', ''));

    try {
      $connection = Database::getConnection('default', 'supabase');

      $query = $connection->select('raw_data', 'r')
        ->fields('r', [
          'id',
          'english_text',
          'vietnamese_text',
          'source',
          'created_at',
        ])
        ->range($offset, $limit)
        ->orderBy('created_at', 'DESC');

      if ($keyword !== '') {
        $or = $query->orConditionGroup()
          ->condition('english_text', '%' . $connection->escapeLike($keyword) . '%', 'LIKE')
          ->condition('vietnamese_text', '%' . $connection->escapeLike($keyword) . '%', 'LIKE');

        $query->condition($or);
      }

      $results = $query->execute()->fetchAll();

      $rows = [];

      foreach ($results as $row) {
        $rows[] = [
          'data' => [
            $row->id,
            $row->english_text,
            $row->vietnamese_text,
            $row->source,
            $row->created_at,
          ],
        ];
      }

      return [
        'intro' => [
          '#markup' => '
            <h2>Bộ câu song ngữ Anh - Việt</h2>
            <p>Dữ liệu được đọc trực tiếp từ bảng <strong>raw_data</strong> trong Supabase.</p>
          ',
        ],

        'search_form' => [
          '#type' => 'inline_template',
          '#template' => '
            <form method="get" style="margin-bottom: 20px;">
              <input
                type="text"
                name="keyword"
                value="{{ keyword }}"
                placeholder="Tìm câu tiếng Anh hoặc tiếng Việt"
                style="width: 360px; padding: 8px;"
              >
              <button type="submit" style="padding: 8px 14px;">Tìm kiếm</button>
            </form>
          ',
          '#context' => [
            'keyword' => $keyword,
          ],
        ],

        'table' => [
          '#type' => 'table',
          '#header' => [
            'ID',
            'Câu tiếng Anh',
            'Câu tiếng Việt',
            'Nguồn',
            'Ngày tạo',
          ],
          '#rows' => $rows,
          '#empty' => 'Không có dữ liệu.',
        ],

        'pager_custom' => [
          '#type' => 'inline_template',
          '#template' => '
            <div style="margin-top: 20px;">
              <a href="?page={{ prev }}&keyword={{ keyword }}">← Trang trước</a>
              <span style="margin: 0 16px;">Trang {{ current }}</span>
              <a href="?page={{ next }}&keyword={{ keyword }}">Trang sau →</a>
            </div>
          ',
          '#context' => [
            'prev' => max(0, $page - 1),
            'next' => $page + 1,
            'current' => $page + 1,
            'keyword' => $keyword,
          ],
        ],
      ];
    }
    catch (\Exception $e) {
      return [
        '#markup' => '
          <h2>Lỗi kết nối Supabase</h2>
          <p><strong>Chi tiết lỗi:</strong></p>
          <pre>' . htmlspecialchars($e->getMessage()) . '</pre>
        ',
      ];
    }
  }

}